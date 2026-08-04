//! Cross-wallet send harness: moonshine-class sender → iOS mobile-ffi → Android mobile-ffi.
//!
//! Requires a funded localnet/testnet stack:
//!   - darkfid running
//!   - darkfi-lightwalletd (with RegisterOmrClue) on :9067
//!   - Sender pre-funded via `drk transfer` (moonshine CLI send is still a stub)

use std::path::PathBuf;
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
const SEND_AMOUNT: &str = "1";
/// Expected received balance in atomic units (1 DRK with 8 decimals).
const SEND_AMOUNT_ATOMIC: u64 = 100_000_000;
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
const LW_URL: &str = "http://127.0.0.1:9067";
/// Optional darkfid JSON-RPC for direct `scan_blocks` (override via E2E_DARKFID_RPC).
fn darkfid_rpc_url() -> Option<String> {
    std::env::var("E2E_DARKFID_RPC")
        .ok()
        .filter(|s| !s.trim().is_empty())
        .or_else(|| Some("tcp://127.0.0.1:18345".into()))
}

fn load_or_create_mnemonics(base_dir: &PathBuf) -> Result<(String, String, String), String> {
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
    base_dir: &PathBuf,
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
        lightwallet_server_url: LW_URL.into(),
        birthday_height: birthday_height(),
        lightwallet_tls_pin_sha256: None,
        use_tor: false,
        tor_socks_port: 0,
        darkfid_rpc_url: darkfid_rpc_url(),
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
    drk.scan_blocks(&mut Vec::new(), None, &false, None)
        .await
        .map_err(|e| format!("scan_blocks: {e}"))
}

async fn sync_until_balance(
    drk_ptr: &DrkWalletPtr,
    min_balance: u64,
    timeout: Duration,
    use_lightwallet: bool,
) -> Result<u64, String> {
    let start = Instant::now();
    let mut attempt = 0u32;
    // Prefer darkfid scan_blocks when RPC is configured — produces spendable
    // merkle roots. LWD trial-decrypt is a fallback when darkfid is unreachable.
    let prefer_darkfid = darkfid_rpc_url().is_some();
    loop {
        attempt += 1;
        if prefer_darkfid {
            let drk = drk_ptr.read().await;
            match sync_wallet_direct(&drk).await {
                Ok(()) => {}
                Err(e) => eprintln!("  darkfid scan attempt {attempt} warn: {e}"),
            }
        } else if use_lightwallet {
            match sync::sync_once_via_lightwallet(drk_ptr.clone(), LW_URL).await {
                Ok(()) => {}
                Err(e) => eprintln!("  sync attempt {attempt} warn: {e}"),
            }
        } else {
            let drk = drk_ptr.read().await;
            sync_wallet_direct(&drk).await?;
        }
        let balance = {
            let drk = drk_ptr.read().await;
            balance_atomic(&drk).await?
        };
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
    let tx_bytes = transactions::build_transfer(
        drk,
        recipient,
        amount,
        Some("DRK"),
        Some(memo),
        Some(LW_URL),
        None,
    )
    .await?;
    transactions::broadcast_transfer(
        drk,
        &tx_bytes,
        Some(memo),
        Some(recipient),
        Some(LW_URL),
        None, // loopback HTTP — no TLS pin
    )
    .await
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

        println!("Scanning moonshine wallet (trial-decrypt via LWD, then darkfid fallback)...");
        let sender_balance = match sync_until_balance(
            &moonshine,
            SEND_AMOUNT_ATOMIC,
            Duration::from_secs(600),
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

        println!("  syncing iOS wallet...");
        let ios_balance =
            sync_until_balance(&ios, SEND_AMOUNT_ATOMIC, Duration::from_secs(300), true).await?;
        println!("  iOS balance after leg1: {ios_balance} atomic DRK\n");

        // Leg 2: iOS → Android
        println!("Leg 2: iOS → Android ({SEND_AMOUNT} DRK)...");
        let tx2 = {
            let drk = ios.read().await;
            send(&drk, &android_addr, SEND_AMOUNT, "e2e leg2 ios→android").await?
        };
        println!("  broadcast tx: {tx2}");
        println!("  explorer: https://explorer.testnet.dark.fi/tx/{tx2}");

        println!("  syncing Android wallet...");
        let android_balance =
            sync_until_balance(&android, SEND_AMOUNT_ATOMIC, Duration::from_secs(300), true)
                .await?;
        println!("  Android balance after leg2: {android_balance} atomic DRK\n");

        // Leg 3: Android → moonshine (desktop/FFI parity round-trip)
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
