//! Cross-wallet send harness: moonshine-class sender → iOS mobile-ffi → Android mobile-ffi.
//!
//! Requires a funded localnet/testnet stack:
//!   - darkfid running
//!   - darkfi-lightwalletd (with RegisterOmrClue) on :9067
//!   - Sender pre-funded via `drk transfer` (moonshine CLI send is still a stub)

use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::{Duration, Instant};

use darkfi_mobile_ffi::bootstrap;
use darkfi_mobile_ffi::mnemonic::DarkfiMnemonic;
use darkfi_mobile_ffi::sync;
use darkfi_mobile_ffi::transactions;
use darkfi_mobile_ffi::unifomr;
use darkfi_mobile_ffi::DrkBootstrapConfig;
use darkfi_mobile_ffi::DrkWalletPtr;
use darkfi_sdk::crypto::pasta_prelude::PrimeField;
use drk::Drk;
use smol::Executor;

/// Human-readable DRK amount (matches iOS/Android `build_transfer` input).
/// Recipients need fee headroom beyond this (fund separately or leave change).
const SEND_AMOUNT: &str = "1";
/// Expected received balance in atomic units (1 DRK with 8 decimals).
const SEND_AMOUNT_ATOMIC: u64 = 100_000_000;
/// Extra DRK that must remain after a hop to cover gas (atomic).
const FEE_HEADROOM_ATOMIC: u64 = 50_000_000;
/// Blockchain network for address encoding.
const NETWORK: &str = "testnet";
/// Wallet birthday. Default `-1` = full history (required for spendable merkle
/// roots via darkfid `scan_blocks`). Override via `E2E_BIRTHDAY`.
fn birthday_height() -> i64 {
    std::env::var("E2E_BIRTHDAY")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(-1)
}
/// lightwalletd gRPC (sync + SendTransaction / RegisterOmrClue).
/// Override with `E2E_LWD_URL` (e.g. reverse-tunneled latest LWD).
fn lw_url() -> String {
    std::env::var("E2E_LWD_URL").unwrap_or_else(|_| "http://127.0.0.1:9067".into())
}
/// Optional darkfid JSON-RPC for direct `scan_blocks` (override via E2E_DARKFID_RPC).
fn darkfid_rpc_url() -> Option<String> {
    std::env::var("E2E_DARKFID_RPC")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .or_else(|| Some("tcp://127.0.0.1:18345".into()))
}

fn load_or_create_mnemonics(base_dir: &Path) -> Result<(String, String, String), String> {
    let path = base_dir.join("mnemonics.txt");
    if path.exists() {
        let text = std::fs::read_to_string(&path).map_err(|e| e.to_string())?;
        let mut lines = text.lines().filter(|l| !l.trim().is_empty());
        let moonshine = lines
            .next()
            .ok_or("missing moonshine mnemonic")?
            .to_string();
        let ios = lines.next().ok_or("missing ios mnemonic")?.to_string();
        let android = lines.next().ok_or("missing android mnemonic")?.to_string();
        return Ok((moonshine, ios, android));
    }

    let engine = DarkfiMnemonic::default();
    let moonshine = engine.make_seed(None, None).map_err(|e| e.to_string())?;
    let ios = engine.make_seed(None, None).map_err(|e| e.to_string())?;
    let android = engine.make_seed(None, None).map_err(|e| e.to_string())?;
    std::fs::write(&path, format!("{moonshine}\n{ios}\n{android}\n")).map_err(|e| e.to_string())?;
    Ok((moonshine, ios, android))
}

fn words_from_phrase(phrase: &str) -> Vec<String> {
    phrase.split_whitespace().map(str::to_string).collect()
}

async fn bootstrap_wallet(
    name: &str,
    mnemonic: &[String],
    base_dir: &Path,
    ex: &Arc<Executor<'static>>,
) -> Result<DrkWalletPtr, String> {
    let wallet_dir = base_dir.join(name);
    std::fs::create_dir_all(&wallet_dir).map_err(|e| format!("mkdir {name}: {e}"))?;

    let config = DrkBootstrapConfig {
        network: NETWORK.into(),
        mnemonic: mnemonic.to_vec(),
        wallet_db_path: wallet_dir.join("wallet.db").to_string_lossy().into(),
        cache_path: wallet_dir.join("cache").to_string_lossy().into(),
        wallet_pass: "e2e-test-pass".into(),
        lightwallet_server_url: lw_url(),
        birthday_height: birthday_height(),
        lightwallet_tls_pin_sha256: None,
        use_tor: false,
        tor_socks_port: 0,
        darkfid_rpc_url: darkfid_rpc_url(),
        strict_omr_only: false,
    };

    bootstrap::bootstrap_drk(&config, ex).await
}

async fn balance_atomic(drk: &Drk) -> Result<u64, String> {
    let balances = drk.money_balance().await.map_err(|e| e.to_string())?;
    Ok(balances.values().copied().sum())
}

async fn default_address(drk: &Drk) -> Result<String, String> {
    use darkfi_sdk::crypto::keypair::{Address, Network, StandardAddress};
    let pubkey = drk.default_address().await.map_err(|e| e.to_string())?;
    let address: Address = StandardAddress::from_public(
        if drk.network.is_testnet() {
            Network::Testnet
        } else {
            Network::Mainnet
        },
        pubkey,
    )
    .into();
    Ok(address.to_string())
}

async fn sync_wallet_direct(drk: &Drk) -> Result<(), String> {
    let mut output = Vec::new();
    drk.scan_blocks(&mut output, None, &false, None)
        .await
        .map_err(|e| format!("scan_blocks: {e}"))?;
    if let Some(first) = output.first() {
        eprintln!("  scan_blocks: {first}");
    }
    if output.len() > 1 {
        if let Some(last) = output.last() {
            eprintln!("  scan_blocks done ({} msgs): {last}", output.len());
        }
    }
    Ok(())
}

async fn sync_until_balance(
    drk_ptr: &DrkWalletPtr,
    min_balance: u64,
    timeout: Duration,
    use_lightwallet: bool,
) -> Result<u64, String> {
    let start = Instant::now();
    let mut attempt = 0u32;
    // LWD GetCoins walks every note commitment from the scan cursor and
    // rebuilds the global Money merkle tree (required for spendable roots).
    // darkfid scan_blocks of full blocks is much slower and a mid-chain
    // birthday produces TransferMerkleRootNotFound (contract error 0x5).
    // Keep darkfid RPC for tx.calculate_fee; only use scan_blocks if LWD fails.
    let prefer_darkfid = std::env::var("E2E_PREFER_DARKFID").ok().as_deref() == Some("1");
    loop {
        attempt += 1;
        let mut darkfid_ok = false;
        if prefer_darkfid {
            let drk = drk_ptr.read().await;
            match sync_wallet_direct(&drk).await {
                Ok(()) => darkfid_ok = true,
                Err(e) => eprintln!("  darkfid scan attempt {attempt} warn: {e}"),
            }
            // Copied full-history caches sit at tip with no decrypted coins.
            // Rewind a few hundred blocks so fee-buffer / hop notes are found
            // without another 45k-block scan.
            if darkfid_ok && attempt == 1 {
                let bal = balance_atomic(&drk).await.unwrap_or(0);
                if bal < min_balance {
                    if let Ok((h, _)) = drk.get_last_scanned_block() {
                        if h > 500 {
                            // Funds may be ~1k blocks behind tip after a paused run.
                            let rewind = h.saturating_sub(1500);
                            eprintln!(
                                "  rewind to height {rewind} (was {h}) to decrypt recent notes"
                            );
                            let mut out = Vec::new();
                            if let Err(e) = drk.reset_to_height(rewind, &mut out).await {
                                eprintln!("  rewind warn: {e}");
                            } else if let Err(e) = sync_wallet_direct(&drk).await {
                                eprintln!("  rescan after rewind warn: {e}");
                            }
                        }
                    }
                }
            }
        }
        // LWD trial-decrypt fallback when darkfid is unset or scan failed
        // (e.g. birthday placeholder hash / tunnel blip).
        if !darkfid_ok && use_lightwallet {
            let lwd = lw_url();
            match sync::sync_once_via_lightwallet(drk_ptr.clone(), &lwd).await {
                Ok(()) => {}
                Err(e) => eprintln!("  lwd sync attempt {attempt} warn: {e}"),
            }
        } else if !prefer_darkfid && !use_lightwallet {
            let drk = drk_ptr.read().await;
            sync_wallet_direct(&drk).await?;
        }
        let balance = {
            let drk = drk_ptr.read().await;
            balance_atomic(&drk).await?
        };
        println!(
            "  sync attempt {attempt}: balance={balance} atomic (elapsed {}s)",
            start.elapsed().as_secs()
        );
        if balance >= min_balance {
            return Ok(balance);
        }
        if start.elapsed() > timeout {
            return Err(format!(
                "timeout waiting for balance >= {min_balance} (have {balance})"
            ));
        }
        smol::Timer::after(Duration::from_secs(2)).await;
    }
}

async fn send(drk: &Drk, recipient: &str, amount: &str, memo: &str) -> Result<String, String> {
    let lwd = lw_url();
    let tx_bytes = transactions::build_transfer(
        drk,
        recipient,
        amount,
        Some("DRK"),
        Some(memo),
        Some(&lwd),
        None,
    )
    .await?;
    transactions::broadcast_transfer(
        drk,
        &tx_bytes,
        Some(memo),
        Some(recipient),
        Some(&lwd),
        None, // loopback HTTP — no TLS pin
    )
    .await
}

/// Register this wallet's UnifOMR clue PK on lightwalletd (no full sync).
async fn register_unifomr_clue(drk_ptr: &DrkWalletPtr) -> Result<(), String> {
    use darkfi_mobile_ffi::lightwallet_client::LightwalletClient;
    use darkfi_sdk::crypto::keypair::Network;

    let drk = drk_ptr.read().await;
    let secret = drk.default_secret().await.map_err(|e| e.to_string())?;
    let secret_bytes: [u8; 32] = secret.inner().to_repr();
    let pay_pk = drk
        .default_address()
        .await
        .map_err(|e| e.to_string())?
        .to_bytes();
    let net = match drk.network {
        Network::Mainnet => 0u8,
        Network::Testnet => 1u8,
    };
    let (_sk, pk) = unifomr::clue_keypair_from_wallet(&secret_bytes, net)?;
    let clue_pk = unifomr::serialize_public_key(&pk);
    let key_version = unifomr::clue_key_version_now();
    let proof = unifomr::sign_clue_pk_ownership(&secret, net, key_version, &pay_pk, &clue_pk);
    let lwd = lw_url();
    let client = LightwalletClient::from_endpoint_and_pin(&lwd, None);
    client
        .register_clue_public_key(pay_pk.to_vec(), clue_pk, proof, key_version)
        .await
}

/// Rebuild the Money Merkle tree from genesis via LWD `GetNoteCommitments`.
///
/// `scan_blocks` from a mid-chain birthday decrypts notes but only appends
/// that window's commitments, so spend proofs use a root that is not on
/// chain (`tx.calculate_fee` → -32111). Walking every commitment and
/// re-marking this wallet's coins restores valid witnesses.
async fn rebuild_money_tree_from_lwd(drk: &Drk, name: &str) -> Result<(), String> {
    use std::collections::HashMap;

    use darkfi_mobile_ffi::lightwallet_client::LightwalletClient;
    use darkfi_sdk::crypto::{MerkleNode, MerkleTree};
    use darkfi_sdk::pasta::group::ff::{Field, PrimeField};
    use darkfi_serial::serialize;
    use drk::money::{MONEY_COINS_COL_COIN, MONEY_COINS_COL_LEAF_POSITION, MONEY_COINS_TABLE};

    let coins = drk.get_coins(true).await.map_err(|e| e.to_string())?;
    if coins.is_empty() {
        println!("  {name}: no coins — skip merkle rebuild");
        return Ok(());
    }

    let mut own: HashMap<[u8; 32], Vec<u8>> = HashMap::new();
    for (oc, _, _, _, _) in &coins {
        own.insert(oc.coin.inner().to_repr(), oc.coin.to_bytes().to_vec());
    }

    let lwd = lw_url();
    let client = LightwalletClient::from_endpoint_and_pin(&lwd, None);
    let info = client.get_light_info().await?;
    let tip = info.chain_tip_height;
    if tip == 0 {
        return Err("LWD tip is 0".into());
    }

    println!("  {name}: rebuilding Money tree 0..={tip} ({} wallet coins)...", own.len());
    // Match on-chain Money: dummy ZERO leaf, then genesis (height 0) coins.
    let mut tree = MerkleTree::new(u32::MAX as usize);
    tree.append(MerkleNode::from(darkfi_sdk::pasta::pallas::Base::ZERO));
    let _ = tree.mark().unwrap();
    let mut marked = 0u32;
    let mut appended = 0u64;
    const CHUNK: u32 = 4096;
    let mut start = 0u32;
    while start <= tip {
        let end = start.saturating_add(CHUNK - 1).min(tip);
        let updates = client.get_note_commitments(start, end).await?;
        let mut by_h: Vec<(u32, Vec<Vec<u8>>)> = updates;
        by_h.sort_by_key(|(h, _)| *h);
        for (_h, commitments) in by_h {
            for coin_bytes in commitments {
                if coin_bytes.len() != 32 {
                    continue;
                }
                let mut repr = [0u8; 32];
                repr.copy_from_slice(&coin_bytes);
                let Some(base) =
                    Option::<darkfi_sdk::pasta::pallas::Base>::from(darkfi_sdk::pasta::pallas::Base::from_repr(repr))
                else {
                    continue;
                };
                tree.append(MerkleNode::from(base));
                appended += 1;
                if let Some(sql_key) = own.get(&repr) {
                    let pos = tree.mark().ok_or_else(|| "merkle mark failed".to_string())?;
                    let query = format!(
                        "UPDATE {} SET {} = ?1 WHERE {} = ?2;",
                        *MONEY_COINS_TABLE,
                        MONEY_COINS_COL_LEAF_POSITION,
                        MONEY_COINS_COL_COIN,
                    );
                    drk.wallet
                        .exec_sql(
                            &query,
                            vec![
                                drk::walletdb::Value::from(serialize(&pos)),
                                drk::walletdb::Value::from(sql_key.clone()),
                            ],
                        )
                        .await
                        .map_err(|e| format!("update leaf_position: {e}"))?;
                    marked += 1;
                }
            }
        }
        start = end.saturating_add(1);
        if start == 0 {
            break;
        }
    }

    drk.cache
        .insert_merkle_trees(&[(drk::money::SLED_MERKLE_TREES_MONEY, &tree)])
        .map_err(|e| format!("persist merkle tree: {e}"))?;
    let _ = drk.cache.sled_db.flush();
    println!("  {name}: merkle rebuild done (appended={appended} marked={marked})");
    if marked == 0 {
        return Err(format!(
            "{name}: rebuilt tree but marked 0 wallet coins — spend proofs will fail"
        ));
    }
    Ok(())
}

#[allow(clippy::too_many_lines)]
fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let base_dir = PathBuf::from(std::env::var("E2E_WALLET_DIR").unwrap_or_else(|_| {
        std::env::temp_dir()
            .join("darkfi_cross_wallet_e2e")
            .to_string_lossy()
            .into()
    }));
    std::fs::create_dir_all(&base_dir)?;

    let ex = darkfi_mobile_ffi::shared_executor();

    let (moonshine_phrase, ios_phrase, android_phrase) = load_or_create_mnemonics(&base_dir)?;

    let moonshine_words = words_from_phrase(&moonshine_phrase);
    let ios_words = words_from_phrase(&ios_phrase);
    let android_words = words_from_phrase(&android_phrase);

    smol::block_on(async {
        println!("=== Cross-wallet e2e: moonshine → iOS → Android ===\n");

        let moonshine = bootstrap_wallet("moonshine", &moonshine_words, &base_dir, &ex).await?;
        let ios = bootstrap_wallet("ios", &ios_words, &base_dir, &ex).await?;
        let android = bootstrap_wallet("android", &android_words, &base_dir, &ex).await?;

        let (moonshine_addr, ios_addr, android_addr) = {
            let m = moonshine.read().await;
            let i = ios.read().await;
            let a = android.read().await;
            (
                default_address(&m).await?,
                default_address(&i).await?,
                default_address(&a).await?,
            )
        };

        println!("Moonshine (sender) address: {moonshine_addr}");
        println!("iOS recipient address:       {ios_addr}");
        println!("Android recipient address:   {android_addr}\n");

        println!("Scanning moonshine wallet (LWD GetCoins full-history merkle rebuild)...");
        let sender_balance = match sync_until_balance(
            &moonshine,
            SEND_AMOUNT_ATOMIC,
            Duration::from_secs(1800),
            true,
        )
        .await
        {
            Ok(bal) => bal,
            Err(e) => {
                eprintln!("  lightwallet sync timed out ({e}); trying darkfid scan_blocks...");
                {
                    let drk = moonshine.read().await;
                    if let Err(scan_e) = sync_wallet_direct(&drk).await {
                        eprintln!("  scan_blocks warn: {scan_e}");
                    }
                }
                let bal = {
                    let drk = moonshine.read().await;
                    balance_atomic(&drk).await?
                };
                if bal == 0 {
                    eprintln!(
                        "ERROR: moonshine wallet has 0 DRK. Fund it first, e.g.:\n\
                         drk -n testnet transfer 10 DRK {moonshine_addr} | drk -n testnet broadcast\n\
                         Explorer (prior fund): https://explorer.testnet.dark.fi/tx/adee118820ae622aed3d2ec3957a91e9e99f21cbf99d5cb6c09a0af219b49d70\n\
                         Then re-run with the same E2E_WALLET_DIR."
                    );
                    std::process::exit(1);
                }
                bal
            }
        };
        println!("Moonshine balance: {sender_balance} atomic DRK\n");

        if std::env::var("E2E_REBUILD_MERKLE").ok().as_deref() == Some("1") {
            println!("Rebuilding moonshine Money merkle tree from LWD commitments...");
            let drk = moonshine.read().await;
            rebuild_money_tree_from_lwd(&drk, "moonshine").await?;
        }

        // All hop endpoints must RegisterCluePublicKey before senders' GetCluePublicKey
        // returns a verifiable clue (otherwise LWD serves a decoy and send fails).
        // Use a lightweight register-only path — full LWD sync is too heavy here.
        println!("Registering UnifOMR clue PKs (moonshine + iOS + Android)...");
        for (name, wallet) in [
            ("moonshine", &moonshine),
            ("ios", &ios),
            ("android", &android),
        ] {
            match register_unifomr_clue(wallet).await {
                Ok(()) => println!("  {name}: RegisterCluePublicKey ok"),
                Err(e) => eprintln!("  {name}: register warn: {e}"),
            }
        }
        println!();

        // Leg 1: moonshine → iOS
        println!("Leg 1: moonshine → iOS ({SEND_AMOUNT} DRK)...");
        let tx1 = {
            let drk = moonshine.read().await;
            send(&drk, &ios_addr, SEND_AMOUNT, "e2e leg1 moonshine→ios").await?
        };
        println!("  broadcast tx: {tx1}");
        println!("  explorer: https://explorer.testnet.dark.fi/tx/{tx1}");

        // Verify recipient has a registerable UnifOMR clue keypair (directory path).
        {
            let drk = ios.read().await;
            let secret = drk.default_secret().await.map_err(|e| e.to_string())?;
            let secret_bytes: [u8; 32] = secret.inner().to_repr();
            let net = match drk.network {
                darkfi_sdk::crypto::keypair::Network::Mainnet => 0u8,
                darkfi_sdk::crypto::keypair::Network::Testnet => 1u8,
            };
            let (_sk, pk) = unifomr::clue_keypair_from_wallet(&secret_bytes, net)?;
            let clue_pk = unifomr::serialize_public_key(&pk);
            println!(
                "  iOS UnifOMR clue pk len={} (senders should GetCluePublicKey)",
                clue_pk.len()
            );
        }

        println!("  syncing iOS wallet (need hop + fee headroom)...");
        let ios_balance = sync_until_balance(
            &ios,
            SEND_AMOUNT_ATOMIC + FEE_HEADROOM_ATOMIC,
            Duration::from_secs(1800),
            true,
        )
        .await?;
        println!("  iOS balance after leg1: {ios_balance} atomic DRK\n");
        if ios_balance < SEND_AMOUNT_ATOMIC + FEE_HEADROOM_ATOMIC {
            return Err(format!(
                "iOS needs >= {} atomic for hop+fees (have {ios_balance}); fund fee buffer",
                SEND_AMOUNT_ATOMIC + FEE_HEADROOM_ATOMIC
            ));
        }

        // Leg 2: iOS → Android
        if std::env::var("E2E_REBUILD_MERKLE").ok().as_deref() == Some("1") {
            println!("Rebuilding iOS Money merkle tree from LWD commitments...");
            let drk = ios.read().await;
            rebuild_money_tree_from_lwd(&drk, "ios").await?;
        }
        println!("Leg 2: iOS → Android ({SEND_AMOUNT} DRK)...");
        let tx2 = {
            let drk = ios.read().await;
            send(&drk, &android_addr, SEND_AMOUNT, "e2e leg2 ios→android").await?
        };
        println!("  broadcast tx: {tx2}");
        println!("  explorer: https://explorer.testnet.dark.fi/tx/{tx2}");

        println!("  syncing Android wallet (need hop + fee headroom)...");
        let android_balance = sync_until_balance(
            &android,
            SEND_AMOUNT_ATOMIC + FEE_HEADROOM_ATOMIC,
            Duration::from_secs(1800),
            true,
        )
        .await?;
        println!("  Android balance after leg2: {android_balance} atomic DRK\n");
        if android_balance < SEND_AMOUNT_ATOMIC + FEE_HEADROOM_ATOMIC {
            return Err(format!(
                "Android needs >= {} atomic for hop+fees (have {android_balance}); fund fee buffer",
                SEND_AMOUNT_ATOMIC + FEE_HEADROOM_ATOMIC
            ));
        }

        // Leg 3: Android → moonshine (desktop/FFI parity round-trip)
        if std::env::var("E2E_REBUILD_MERKLE").ok().as_deref() == Some("1") {
            println!("Rebuilding Android Money merkle tree from LWD commitments...");
            let drk = android.read().await;
            rebuild_money_tree_from_lwd(&drk, "android").await?;
        }
        println!("Leg 3: Android → moonshine ({SEND_AMOUNT} DRK)...");
        let tx3 = {
            let drk = android.read().await;
            send(&drk, &moonshine_addr, SEND_AMOUNT, "e2e leg3 android→moonshine").await?
        };
        println!("  broadcast tx: {tx3}");
        println!("  explorer: https://explorer.testnet.dark.fi/tx/{tx3}");

        println!("=== PASS: cross-wallet send moonshine → iOS → Android → moonshine ===");
        println!("Explorer links:");
        println!("  leg1 moonshine→ios:     https://explorer.testnet.dark.fi/tx/{tx1}");
        println!("  leg2 ios→android:       https://explorer.testnet.dark.fi/tx/{tx2}");
        println!("  leg3 android→moonshine: https://explorer.testnet.dark.fi/tx/{tx3}");
        println!("Mnemonics (for manual UI / desktop replay):");
        println!("  moonshine: {moonshine_phrase}");
        println!("  ios:       {ios_phrase}");
        println!("  android:   {android_phrase}");

        Ok::<(), String>(())
    })
    .map_err(|e| -> Box<dyn std::error::Error> { e.into() })?;

    Ok(())
}
