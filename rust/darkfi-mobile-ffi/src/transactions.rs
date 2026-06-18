//! Transfer build/broadcast and wallet transaction history for UniFFI.

use std::str::FromStr;

use darkfi::tx::Transaction;
use darkfi_sdk::crypto::keypair::Address;
use darkfi_serial::{deserialize_async, serialize_async};
use drk::Drk;

use crate::{
    memo::parse_payment_memo,
    tx_inspect::{contract_summary_for_tx, net_value_atomic},
    DrkTransactionRecord,
};

use std::collections::HashMap;
use std::sync::LazyLock;
use smol::lock::RwLock;

static PAYMENT_MEMOS: LazyLock<RwLock<HashMap<String, String>>> =
    LazyLock::new(|| RwLock::new(HashMap::new()));
static OUTGOING_RECIPIENTS: LazyLock<RwLock<HashMap<String, String>>> =
    LazyLock::new(|| RwLock::new(HashMap::new()));

pub async fn build_transfer(
    drk: &Drk,
    recipient_address: &str,
    amount: &str,
    token_id: Option<&str>,
    payment_memo: Option<&str>,
) -> Result<Vec<u8>, String> {
    let recipient = Address::from_str(recipient_address.trim())
        .map_err(|e| format!("recipient address: {e}"))?;
    let token_input = token_id
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("DRK")
        .to_string();
    let token = drk
        .get_token(token_input)
        .await
        .map_err(|e| format!("token: {e}"))?;

    let _memo_bytes = parse_payment_memo(payment_memo)?;

    let tx = drk
        .transfer(
            amount,
            token,
            *recipient.public_key(),
            None,
            None,
            false,
        )
        .await
        .map_err(|e| format!("transfer: {e}"))?;

    Ok(serialize_async(&tx).await)
}

pub async fn broadcast_transfer(
    drk: &Drk,
    tx_bytes: &[u8],
    payment_memo: Option<&str>,
    recipient_address: Option<&str>,
) -> Result<String, String> {
    let tx: Transaction = deserialize_async(tx_bytes)
        .await
        .map_err(|e| format!("decode tx: {e}"))?;

    drk.simulate_tx(&tx)
        .await
        .map_err(|e| format!("simulate_tx: {e}"))?;

    let mut output = Vec::new();
    drk.mark_tx_spend(&tx, &mut output)
        .await
        .map_err(|e| format!("mark_tx_spend: {e}"))?;

    drk.broadcast_tx(&tx, &mut output)
        .await
        .map_err(|e| format!("broadcast_tx: {e}"))?;

    let tx_hash = tx.hash().to_string();

    if let Some(memo) = payment_memo {
        let _parsed = parse_payment_memo(Some(memo))?;
        PAYMENT_MEMOS.write().await.insert(tx_hash.clone(), memo.to_string());
    }

    if let Some(recipient) = recipient_address.map(str::trim).filter(|s| !s.is_empty()) {
        OUTGOING_RECIPIENTS.write().await.insert(tx_hash.clone(), recipient.to_string());
    }

    Ok(tx_hash)
}

pub async fn estimate_transfer_fee(
    drk: &Drk,
    recipient_address: &str,
    amount: &str,
    token_id: Option<&str>,
    payment_memo: Option<&str>,
) -> Result<i64, String> {
    let tx_bytes = build_transfer(drk, recipient_address, amount, token_id, payment_memo).await?;
    let tx: Transaction = deserialize_async(&tx_bytes)
        .await
        .map_err(|e| format!("decode tx: {e}"))?;
    let fee = drk
        .get_tx_fee(&tx, true)
        .await
        .map_err(|e| format!("get_tx_fee: {e}"))?;
    i64::try_from(fee).map_err(|_| format!("fee out of range: {fee}"))
}

pub async fn get_transaction_memo(_drk: &Drk, tx_hash: &str) -> Result<Option<String>, String> {
    Ok(PAYMENT_MEMOS.read().await.get(tx_hash.trim()).cloned())
}

pub async fn get_transaction_recipient(_drk: &Drk, tx_hash: &str) -> Result<Option<String>, String> {
    Ok(OUTGOING_RECIPIENTS.read().await.get(tx_hash.trim()).cloned())
}

pub async fn list_transaction_history(drk: &Drk) -> Result<Vec<DrkTransactionRecord>, String> {
    let rows = drk.get_txs_history().map_err(|e| e.to_string())?;
    let mut records = Vec::with_capacity(rows.len());

    for (tx_hash, status, block_height) in rows {
        let is_sent = status == "Broadcasted";
        let mut fee_atomic = 0i64;
        let mut net_atomic = 0i64;
        let contract_summary;
        let recipient_address = OUTGOING_RECIPIENTS.read().await.get(&tx_hash).cloned();

        match drk.get_tx_history_record(&tx_hash).await {
            Ok((_, _, _, tx)) => {
                contract_summary = contract_summary_for_tx(&tx);
                fee_atomic = drk
                    .get_tx_fee(&tx, true)
                    .await
                    .ok()
                    .and_then(|f| i64::try_from(f).ok())
                    .unwrap_or(0);
                net_atomic = net_value_atomic(drk, &tx).await.unwrap_or(0);
            }
            Err(_) => {
                contract_summary = if is_sent {
                    "Outgoing transfer".to_string()
                } else {
                    "Transaction".to_string()
                };
            }
        }

        records.push(DrkTransactionRecord {
            tx_hash,
            status,
            block_height: block_height.map(i64::from).unwrap_or(-1),
            fee_atomic,
            is_sent,
            net_value_atomic: net_atomic,
            contract_summary,
            recipient_address,
        });
    }

    Ok(records)
}
