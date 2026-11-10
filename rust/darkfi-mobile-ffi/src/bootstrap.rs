use std::sync::Arc;

use darkfi_sdk::crypto::keypair::Network;
use drk::Drk;
use smol::Executor;

use crate::birthday::{seed_birthday_scan_cursor, seed_scan_cursor};
use crate::lightwallet_client::LightwalletClient;
use crate::mnemonic::{
    derivation_seed_from_mnemonic, secret_key_from_mnemonic, secret_key_from_seed_index,
};
use crate::DrkBootstrapConfig;
use crate::DrkPtr;

pub async fn bootstrap_drk(
    config: &DrkBootstrapConfig,
    ex: &Arc<Executor<'static>>,
) -> Result<DrkPtr, String> {
    // LWD-first: do not bind a hardcoded darkfid RPC. Broadcast falls back to
    // `drk.broadcast_tx` only when `rpc_client` is Some; leaving it None makes
    // that path fail closed so we never hit the wrong network (e.g. :18345).
    let darkfid_endpoint = config
        .darkfid_rpc_url
        .as_ref()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| url::Url::parse(s).map_err(|e| format!("darkfid_rpc_url: {e}")))
        .transpose()?;

    let drk = Drk::new(
        parse_network(&config.network),
        config.cache_path.clone(),
        config.wallet_db_path.clone(),
        config.wallet_pass.clone(),
        darkfid_endpoint,
        ex,
        false,
    )
    .await
    .map_err(|e| format!("Drk::new: {e}"))?;

    drk.initialize_wallet()
        .await
        .map_err(|e| format!("initialize_wallet: {e}"))?;

    let mut output = Vec::new();
    drk.initialize_money(&mut output)
        .await
        .map_err(|e| format!("initialize_money: {e}"))?;

    let _ = drk.initialize_dao().await;
    let _ = drk.initialize_deployooor();

    ensure_default_money_key(&drk, &config.mnemonic, &mut output).await?;

    if config.birthday_height > 0 {
        let birthday = u32::try_from(config.birthday_height)
            .map_err(|_| format!("birthday_height out of range: {}", config.birthday_height))?;
        let pin = pin_from_config(config);
        let client =
            LightwalletClient::from_endpoint_and_pin(&config.lightwallet_server_url, pin);
        if crate::checkpoint::download_and_apply_checkpoint(&drk, &client, birthday)
            .await
            .is_err()
        {
            seed_birthday_scan_cursor(&drk, birthday).await?;
        }
    } else if config.birthday_height == 0 {
        // Fresh create (birthday 0): prefer a verified checkpoint snapshot.
        // If the server has none, jump the scan cursor to the LWD tip.
        // Non-fatal: devices often default to 127.0.0.1:9067 which is unreachable
        // until a remote LWD is configured. Sync can seed the tip later.
        let pin = pin_from_config(config);
        let client =
            LightwalletClient::from_endpoint_and_pin(&config.lightwallet_server_url, pin);
        if crate::checkpoint::download_and_apply_checkpoint(&drk, &client, 0)
            .await
            .is_err()
        {
            if let Err(e) =
                seed_fresh_wallet_at_tip(&drk, &config.lightwallet_server_url, pin).await
            {
                tracing::warn!(
                    target: "wallet-bootstrap",
                    "Fresh-wallet tip probe skipped (wallet still opens): {e}"
                );
            }
        }
    }
    // birthday_height < 0 (e.g. -1): unknown restore birthday — full history scan.

    Ok(drk.into_ptr())
}

fn pin_from_config(config: &DrkBootstrapConfig) -> Option<[u8; 32]> {
    let bytes = config.lightwallet_tls_pin_sha256.as_ref()?;
    if bytes.len() != 32 {
        return None;
    }
    let mut pin = [0u8; 32];
    pin.copy_from_slice(bytes);
    Some(pin)
}

/// Seed an empty wallet at the current lightwalletd tip (create-at-tip).
async fn seed_fresh_wallet_at_tip(
    drk: &Drk,
    lwd_url: &str,
    tls_pin: Option<[u8; 32]>,
) -> Result<(), String> {
    let (last, _) = drk.get_last_scanned_block().map_err(|e| e.to_string())?;
    if last > 0 {
        return Ok(());
    }
    // Same transport policy as sync (remote HTTPS requires pin).
    let client = LightwalletClient::from_endpoint_and_pin(lwd_url, tls_pin);
    let info = client
        .get_light_info()
        .await
        .map_err(|e| format!("fresh-wallet tip probe: {e}"))?;
    if info.chain_tip_height == 0 {
        return Ok(());
    }
    seed_scan_cursor(drk, info.chain_tip_height, None)?;
    tracing::info!(
        target: "wallet-bootstrap",
        "Fresh wallet seeded at tip {} (no history scan)",
        info.chain_tip_height
    );
    Ok(())
}

async fn ensure_default_money_key(
    drk: &Drk,
    mnemonic: &[String],
    output: &mut Vec<String>,
) -> Result<(), String> {
    persist_hd_seed(drk, &derivation_seed_from_mnemonic(mnemonic)).await?;
    if drk.default_address().await.is_ok() {
        restore_hd_extra_keys(drk, mnemonic, output).await?;
        return Ok(());
    }

    let secret = secret_key_from_mnemonic(mnemonic)?;
    drk.import_money_secrets(vec![secret], output)
        .await
        .map_err(|e| format!("import_money_secrets: {e}"))?;

    if let Ok(addrs) = drk.addresses().await {
        if let Some((key_id, _, _, _)) = addrs.last() {
            let idx = u16::try_from(*key_id)
                .map_err(|_| format!("set_default_address: key_id {key_id} out of u16 range"))?;
            drk.set_default_address(idx)
                .await
                .map_err(|e| format!("set_default_address: {e}"))?;
        }
    }

    restore_hd_extra_keys(drk, mnemonic, output).await?;
    Ok(())
}

const HD_META_TABLE: &str = "nighthawk_hd_meta";
const HD_KEY_SEED: &str = "derivation_seed";
const HD_KEY_NEXT: &str = "next_index";

async fn ensure_hd_meta_table(drk: &Drk) -> Result<(), String> {
    drk.wallet
        .exec_batch_sql(&format!(
            "CREATE TABLE IF NOT EXISTS {HD_META_TABLE} (k TEXT PRIMARY KEY, v BLOB NOT NULL);"
        ))
        .await
        .map_err(|e| format!("hd meta table: {e}"))
}

fn hd_sql_params(key: &str, value: Vec<u8>) -> Vec<drk::walletdb::Value> {
    vec![
        drk::walletdb::Value::from(key.to_string()),
        drk::walletdb::Value::from(value),
    ]
}

fn hd_lookup_params(key: &str) -> Vec<(String, drk::walletdb::Value)> {
    vec![(
        String::from(":k"),
        drk::walletdb::Value::from(key.to_string()),
    )]
}

async fn persist_hd_seed(drk: &Drk, seed: &[u8; 32]) -> Result<(), String> {
    ensure_hd_meta_table(drk).await?;
    let query = format!("INSERT OR REPLACE INTO {HD_META_TABLE} (k, v) VALUES (?1, ?2);");
    drk.wallet
        .exec_sql(&query, hd_sql_params(HD_KEY_SEED, seed.to_vec()))
        .await
        .map_err(|e| format!("persist hd seed: {e}"))?;
    if load_hd_next_index(drk).await.unwrap_or(0) == 0 {
        persist_hd_next_index(drk, 1).await?;
    }
    Ok(())
}

async fn load_hd_seed(drk: &Drk) -> Result<Option<[u8; 32]>, String> {
    ensure_hd_meta_table(drk).await?;
    let row = drk
        .wallet
        .query_single(HD_META_TABLE, &["v"], hd_lookup_params(HD_KEY_SEED))
        .await
        .ok();
    let Some(row) = row else {
        return Ok(None);
    };
    let Some(drk::walletdb::Value::Blob(bytes)) = row.into_iter().next() else {
        return Ok(None);
    };
    if bytes.len() != 32 {
        return Ok(None);
    }
    let mut seed = [0u8; 32];
    seed.copy_from_slice(&bytes);
    Ok(Some(seed))
}

async fn persist_hd_next_index(drk: &Drk, next: u32) -> Result<(), String> {
    ensure_hd_meta_table(drk).await?;
    let query = format!("INSERT OR REPLACE INTO {HD_META_TABLE} (k, v) VALUES (?1, ?2);");
    drk.wallet
        .exec_sql(
            &query,
            hd_sql_params(HD_KEY_NEXT, next.to_le_bytes().to_vec()),
        )
        .await
        .map_err(|e| format!("persist hd next_index: {e}"))
}

async fn load_hd_next_index(drk: &Drk) -> Result<u32, String> {
    ensure_hd_meta_table(drk).await?;
    let row = drk
        .wallet
        .query_single(HD_META_TABLE, &["v"], hd_lookup_params(HD_KEY_NEXT))
        .await
        .ok();
    let Some(row) = row else {
        return Ok(1);
    };
    let Some(drk::walletdb::Value::Blob(bytes)) = row.into_iter().next() else {
        return Ok(1);
    };
    if bytes.len() != 4 {
        return Ok(1);
    }
    Ok(u32::from_le_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
}

async fn restore_hd_extra_keys(
    drk: &Drk,
    mnemonic: &[String],
    output: &mut Vec<String>,
) -> Result<(), String> {
    let seed = derivation_seed_from_mnemonic(mnemonic);
    persist_hd_seed(drk, &seed).await?;
    let next = load_hd_next_index(drk).await.unwrap_or(1);
    if next <= 1 {
        return Ok(());
    }
    let mut secrets = Vec::new();
    for index in 1..next {
        secrets.push(secret_key_from_seed_index(&seed, index)?);
    }
    if !secrets.is_empty() {
        drk.import_money_secrets(secrets, output)
            .await
            .map_err(|e| format!("restore hd keys: {e}"))?;
    }
    Ok(())
}

/// Derive the next HD address (index >= 1). Never creates a random key.
/// Addresses created this way restore from the mnemonic. Older random
/// `money_keygen` addresses cannot.
pub async fn generate_hd_address(drk: &Drk) -> Result<String, String> {
    use darkfi_sdk::crypto::keypair::{Address, StandardAddress};
    use darkfi_sdk::crypto::PublicKey;

    let Some(seed) = load_hd_seed(drk).await? else {
        tracing::debug!(
            target: "wallet-addr",
            "generate_new_address: no HD seed; returning default address"
        );
        let pubkey = drk.default_address().await.map_err(|e| e.to_string())?;
        let address: Address = StandardAddress::from_public(drk.network, pubkey).into();
        return Ok(address.to_string());
    };
    let index = load_hd_next_index(drk).await.unwrap_or(1);
    let secret = secret_key_from_seed_index(&seed, index)?;
    let mut output = Vec::new();
    drk.import_money_secrets(vec![secret], &mut output)
        .await
        .map_err(|e| format!("import hd key: {e}"))?;
    persist_hd_next_index(drk, index.saturating_add(1)).await?;
    let pubkey = PublicKey::from_secret(secret);
    let address: Address = StandardAddress::from_public(drk.network, pubkey).into();
    Ok(address.to_string())
}

fn parse_network(network: &str) -> Network {
    match network.trim() {
        "mainnet" => Network::Mainnet,
        _ => Network::Testnet, // testnet + localnet share Testnet address encoding
    }
}
