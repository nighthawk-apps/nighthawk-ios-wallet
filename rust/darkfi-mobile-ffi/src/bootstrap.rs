use std::sync::Arc;

use darkfi_sdk::crypto::keypair::Network;
use drk::Drk;
use smol::Executor;
use url::Url;

use crate::birthday::seed_birthday_scan_cursor;
use crate::mnemonic::secret_key_from_mnemonic;
use crate::DrkBootstrapConfig;
use crate::DrkPtr;

/// Permitted URL schemes for the darkfid JSON-RPC endpoint.
const ALLOWED_SCHEMES: &[&str] = &["tcp", "tcp+tls", "socks5"];

pub fn parse_darkfid_endpoint(url: &str) -> Result<Url, String> {
    let parsed = Url::parse(url.trim()).map_err(|e| format!("invalid darkfid endpoint URL: {e}"))?;
    if !ALLOWED_SCHEMES.contains(&parsed.scheme()) {
        return Err(format!(
            "unsupported URL scheme '{}' — allowed: {}",
            parsed.scheme(),
            ALLOWED_SCHEMES.join(", ")
        ));
    }
    Ok(parsed)
}

pub async fn bootstrap_drk(
    config: &DrkBootstrapConfig,
    ex: &Arc<Executor<'static>>,
) -> Result<DrkPtr, String> {
    let endpoint = parse_darkfid_endpoint(&config.darkfid_endpoint_url)?;
    let drk = Drk::new(
        parse_network(&config.network),
        config.cache_path.clone(),
        config.wallet_db_path.clone(),
        config.wallet_pass.clone(),
        Some(endpoint),
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
        seed_birthday_scan_cursor(&drk, birthday).await?;
    }

    Ok(drk.into_ptr())
}

async fn ensure_default_money_key(
    drk: &Drk,
    mnemonic: &[String],
    output: &mut Vec<String>,
) -> Result<(), String> {
    if drk.default_address().await.is_ok() {
        return Ok(());
    }

    let secret = secret_key_from_mnemonic(mnemonic)?;
    drk.import_money_secrets(vec![secret], output)
        .await
        .map_err(|e| format!("import_money_secrets: {e}"))?;

    if let Ok(addrs) = drk.addresses().await {
        if let Some((key_id, _, _, _)) = addrs.last() {
            drk.set_default_address(*key_id as usize)
                .map_err(|e| format!("set_default_address: {e}"))?;
        }
    }

    Ok(())
}

fn parse_network(network: &str) -> Network {
    if network.trim() == "mainnet" {
        Network::Mainnet
    } else {
        Network::Testnet
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_darkfid_endpoint_accepts_upstream_tcp_url() {
        let url = parse_darkfid_endpoint("tcp://127.0.0.1:18345").unwrap();
        // The `url` crate normalizes scheme-authority URLs with a trailing slash.
        assert_eq!(url.as_str(), "tcp://127.0.0.1:18345/");
    }

    #[test]
    fn parse_darkfid_endpoint_rejects_garbage() {
        assert!(parse_darkfid_endpoint("not-a-url").is_err());
    }
}
