//! UniFFI entry for the iOS wallet (`libdarkfi_mobile_ffi`).
//!
//! Exact parity with Android's rust/darkfi-mobile-ffi/src/lib.rs.
//! Links upstream **`bin/drk`** when `third_party/darkfi` is vendored.

mod birthday;
mod bootstrap;
mod dao;
mod darkirc_daemon;
mod mnemonic;
mod sync;
mod memo;
mod tokens;
mod tor;
mod transactions;
mod tx_inspect;

pub use tor::{start_arti_proxy, stop_arti_proxy, is_arti_running};
pub use darkirc_daemon::{start_darkirc, stop_darkirc, darkirc_status, send_chat_message};

pub trait DarkircEventCallback: Send + Sync {
    fn on_message(&self, channel: String, nick: String, message: String, timestamp_ms: u64);
}

use std::sync::{Arc, OnceLock};

use darkfi_sdk::crypto::keypair::{Address, StandardAddress};
use drk::Drk;
use smol::{lock::RwLock, Executor};
use crypto_box::aead::Aead;

type DrkPtr = Arc<RwLock<Drk>>;

#[derive(Debug, thiserror::Error)]
pub enum DarkfiWalletNativeError {
    #[error("wallet not initialized")]
    WalletNotInitialized,
    #[error("invalid bootstrap config")]
    InvalidBootstrapConfig,
    #[error("native drk unavailable: {0}")]
    NativeDrkUnavailable(String),
}

type ResultWallet<T> = Result<T, DarkfiWalletNativeError>;

/// Bootstrap fields mirroring upstream **`DrkPlugin::new`** / `Drk::new` inputs.
#[derive(Debug, Clone)]
pub struct DrkBootstrapConfig {
    pub network: String,
    pub mnemonic: Vec<String>,
    pub wallet_db_path: String,
    pub cache_path: String,
    pub wallet_pass: String,
    pub darkfid_endpoint_url: String,
    /// `-1` when birthday height is unknown.
    pub birthday_height: i64,
}

/// Block scan progress returned from [`DarkfiWalletHandle::refresh_now`].
#[derive(Debug, Clone)]
pub struct DrkSyncSnapshot {
    pub scanned_blocks: i64,
    pub chain_tip: i64,
}

/// Per-token balance for portfolio / send picker.
#[derive(Debug, Clone)]
pub struct DrkTokenBalance {
    pub token_id: String,
    pub display_label: Option<String>,
    pub balance_atomic: i64,
}

/// Wallet transaction history row.
#[derive(Debug, Clone)]
pub struct DrkTransactionRecord {
    pub tx_hash: String,
    pub status: String,
    /// `-1` when the transaction is not yet mined.
    pub block_height: i64,
    pub fee_atomic: i64,
    pub is_sent: bool,
    pub net_value_atomic: i64,
    pub contract_summary: String,
    pub recipient_address: Option<String>,
}

/// Imported DAO summary (`drk dao list`).
#[derive(Debug, Clone)]
pub struct DrkDaoSummary {
    pub name: String,
    pub bulla_b58: String,
    pub gov_token_id: String,
    pub quorum_display: String,
    pub proposer_limit_display: String,
    pub approval_ratio_percent: f64,
    pub mint_height: i64,
    pub can_propose: bool,
    pub can_vote: bool,
    pub can_exec: bool,
}

/// DAO proposal row for list UIs.
#[derive(Debug, Clone)]
pub struct DrkDaoProposalSummary {
    pub proposal_bulla_b58: String,
    pub dao_name: String,
    pub dao_bulla_b58: String,
    pub auth_call_count: u32,
    pub duration_blockwindows: u64,
    pub creation_blockwindow: u64,
    pub mint_height: i64,
    pub exec_height: i64,
    pub is_executed: bool,
    pub summary_line: String,
}

/// Full proposal detail (`drk dao proposal <bulla>`).
#[derive(Debug, Clone)]
pub struct DrkDaoProposalDetail {
    pub proposal_bulla_b58: String,
    pub dao_name: String,
    pub dao_bulla_b58: String,
    pub auth_call_count: u32,
    pub duration_blockwindows: u64,
    pub creation_blockwindow: u64,
    pub mint_height: i64,
    pub exec_height: i64,
    pub is_executed: bool,
    pub summary_line: String,
    pub propose_tx_hash: Option<String>,
    pub exec_tx_hash: Option<String>,
    pub has_plaintext_data: bool,
}

static EXECUTOR: OnceLock<Arc<Executor<'static>>> = OnceLock::new();

fn shared_executor() -> Arc<Executor<'static>> {
    EXECUTOR
        .get_or_init(|| {
            let ex = Arc::new(Executor::new());
            let run_ex = ex.clone();
            std::thread::Builder::new()
                .name("darkfi-mobile-ffi-smol".into())
                .spawn(move || {
                    let _ = smol::block_on(run_ex.run(futures::future::pending::<()>()));
                })
                .expect("spawn smol executor thread");
            ex
        })
        .clone()
}

fn block_on<F: std::future::Future>(future: F) -> F::Output {
    smol::block_on(future)
}

fn bridge_version() -> String {
    env!("CARGO_PKG_VERSION").to_owned()
}

fn bridge_ping() -> String {
    "pong".to_owned()
}

fn validate_bootstrap(config: &DrkBootstrapConfig) -> ResultWallet<()> {
    let network = config.network.trim();
    if network != "mainnet" && network != "testnet" {
        return Err(DarkfiWalletNativeError::InvalidBootstrapConfig);
    }
    let words = config.mnemonic.len();
    if words != 12 && words != 22 {
        return Err(DarkfiWalletNativeError::InvalidBootstrapConfig);
    }
    if config.wallet_db_path.trim().is_empty() || config.cache_path.trim().is_empty() {
        return Err(DarkfiWalletNativeError::InvalidBootstrapConfig);
    }
    if config.wallet_pass.is_empty() || config.darkfid_endpoint_url.trim().is_empty() {
        return Err(DarkfiWalletNativeError::InvalidBootstrapConfig);
    }
    bootstrap::parse_darkfid_endpoint(&config.darkfid_endpoint_url)
        .map_err(|_| DarkfiWalletNativeError::InvalidBootstrapConfig)?;
    Ok(())
}

async fn sync_snapshot_for(drk: &Drk) -> Result<DrkSyncSnapshot, String> {
    let (scanned, _) = drk.get_last_scanned_block().map_err(|e| e.to_string())?;
    let (tip, _) = drk
        .get_last_confirmed_block()
        .await
        .map_err(|e| e.to_string())?;
    Ok(DrkSyncSnapshot {
        scanned_blocks: i64::from(scanned),
        chain_tip: i64::from(tip),
    })
}

/// Opaque handle for an on-device `Drk` session (upstream `bin/drk/src/lib.rs`).
pub struct DarkfiWalletHandle {
    drk: DrkPtr,
    _sync_started: bool,
}

impl std::fmt::Debug for DarkfiWalletHandle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("DarkfiWalletHandle").finish_non_exhaustive()
    }
}

impl DarkfiWalletHandle {
    fn new(config: DrkBootstrapConfig) -> ResultWallet<Self> {
        validate_bootstrap(&config)?;
        let ex = shared_executor();
        let endpoint =
            bootstrap::parse_darkfid_endpoint(&config.darkfid_endpoint_url).map_err(|_| {
                DarkfiWalletNativeError::InvalidBootstrapConfig
            })?;
        let drk = block_on(async { bootstrap::bootstrap_drk(&config, &ex).await })
            .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)?;
        sync::start_background_sync(drk.clone(), endpoint, ex);
        Ok(Self {
            drk,
            _sync_started: true,
        })
    }

    fn confirmed_balance_atomic(&self) -> ResultWallet<i64> {
        let drk = self.drk.clone();
        let balances = block_on(async move {
            let drk = drk.read().await;
            drk.money_balance().await.map_err(|e| e.to_string())
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)?;

        let total: u64 = balances.into_values().sum();
        Ok(i64::try_from(total).unwrap_or(i64::MAX))
    }

    fn primary_deposit_address(&self) -> ResultWallet<String> {
        let drk = self.drk.clone();
        let address = block_on(async move {
            let drk = drk.read().await;
            let pubkey = drk.default_address().await.map_err(|e| e.to_string())?;
            let network = drk.network;
            let address: Address = StandardAddress::from_public(network, pubkey).into();
            Ok::<String, String>(address.to_string())
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)?;

        Ok(address)
    }

    fn refresh_now(&self) -> ResultWallet<DrkSyncSnapshot> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            drk.scan_blocks(&mut Vec::new(), None, &false, None)
                .await
                .map_err(|e| format!("scan_blocks: {e}"))?;
            sync_snapshot_for(&drk).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn sync_snapshot(&self) -> ResultWallet<DrkSyncSnapshot> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            sync_snapshot_for(&drk).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn build_transfer(
        &self,
        recipient_address: String,
        amount: String,
        token_id: Option<String>,
        payment_memo: Option<String>,
    ) -> ResultWallet<Vec<u8>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            transactions::build_transfer(
                &drk,
                &recipient_address,
                &amount,
                token_id.as_deref(),
                payment_memo.as_deref(),
            )
            .await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn estimate_transfer_fee(
        &self,
        recipient_address: String,
        amount: String,
        token_id: Option<String>,
        payment_memo: Option<String>,
    ) -> ResultWallet<i64> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            transactions::estimate_transfer_fee(
                &drk,
                &recipient_address,
                &amount,
                token_id.as_deref(),
                payment_memo.as_deref(),
            )
            .await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn broadcast_transfer(
        &self,
        tx_bytes: Vec<u8>,
        payment_memo: Option<String>,
        recipient_address: Option<String>,
    ) -> ResultWallet<String> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            transactions::broadcast_transfer(
                &drk,
                &tx_bytes,
                payment_memo.as_deref(),
                recipient_address.as_deref(),
            )
            .await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn transaction_payment_memo(&self, tx_hash: String) -> ResultWallet<Option<String>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            transactions::get_transaction_memo(&drk, &tx_hash).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn transaction_recipient(&self, tx_hash: String) -> ResultWallet<Option<String>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            transactions::get_transaction_recipient(&drk, &tx_hash).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn list_token_balances(&self) -> ResultWallet<Vec<DrkTokenBalance>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            tokens::list_token_balances(&drk).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn list_transactions(&self) -> ResultWallet<Vec<DrkTransactionRecord>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            transactions::list_transaction_history(&drk).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn generate_new_address(&self) -> ResultWallet<String> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            let mut output = Vec::new();
            drk.money_keygen(&mut output).await.map_err(|e| e.to_string())?;
            output.last().cloned().ok_or_else(|| "No address generated".to_string())
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn list_addresses(&self) -> ResultWallet<Vec<String>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            let addrs = drk.addresses().await.map_err(|e| e.to_string())?;
            let network = drk.network;
            let mut res = Vec::new();
            for (_, pubkey, _, _) in addrs {
                let address: Address = StandardAddress::from_public(network, pubkey).into();
                res.push(address.to_string());
            }
            Ok::<Vec<String>, String>(res)
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    // ── DAO Hub ──────────────────────────────────────────────────────────

    fn list_daos(&self) -> ResultWallet<Vec<DrkDaoSummary>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            dao::list_daos(&drk).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn list_proposals(&self, dao_name: Option<String>) -> ResultWallet<Vec<DrkDaoProposalSummary>> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            dao::list_proposals(&drk, dao_name).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }

    fn get_proposal(&self, proposal_bulla_b58: String) -> ResultWallet<DrkDaoProposalDetail> {
        let drk = self.drk.clone();
        block_on(async move {
            let drk = drk.read().await;
            dao::get_proposal(&drk, &proposal_bulla_b58).await
        })
        .map_err(DarkfiWalletNativeError::NativeDrkUnavailable)
    }
}

/// Generates a new 22-word DarkFi mnemonic phrase (English).
pub fn generate_darkfi_mnemonic() -> Vec<String> {
    let mnemonic_engine = mnemonic::DarkfiMnemonic::default();
    let phrase = mnemonic_engine.make_seed(None, None).expect("generate seed");
    phrase.split_whitespace().map(|s| s.to_string()).collect()
}

/// Generates a new 12-word BIP-39 mnemonic for Chat Identity.
pub fn generate_bip39_chat_mnemonic() -> Vec<String> {
    use bip39::Mnemonic;
    let mut entropy = [0u8; 16];
    rand::RngCore::fill_bytes(&mut rand::thread_rng(), &mut entropy);
    let mnemonic = Mnemonic::from_entropy(&entropy).expect("entropy is 16 bytes");
    mnemonic.words().map(|s| s.to_string()).collect()
}

/// Validates a DarkFi mnemonic phrase.
pub fn validate_darkfi_mnemonic(phrase: Vec<String>) -> bool {
    let phrase_str = phrase.join(" ");
    let mnemonic_engine = mnemonic::DarkfiMnemonic::default();
    mnemonic_engine.mnemonic_decode(&phrase_str).is_ok()
}

/// Decodes 12-word phrase to entropy bytes if valid.
pub fn decode_chat_entropy(phrase: Vec<String>) -> Option<Vec<u8>> {
    use bip39::Mnemonic;
    if phrase.len() != 12 { return None; }
    let phrase_str = phrase.join(" ");
    if let Ok(mnemonic) = Mnemonic::parse(&phrase_str) {
        Some(mnemonic.to_entropy().to_vec())
    } else {
        None
    }
}

/// ChaChaBox DM keypair (base58-encoded secret + public keys).
#[derive(Debug, Clone)]
pub struct DmKeypair {
    pub secret_b58: String,
    pub public_b58: String,
}

/// Generates a new ChaChaBox DM keypair for E2E encrypted chat.
pub fn generate_dm_keypair() -> DmKeypair {
    let secret_key = crypto_box::SecretKey::generate(&mut rand::thread_rng());
    let public_key = secret_key.public_key();
    DmKeypair {
        secret_b58: bs58::encode(secret_key.to_bytes()).into_string(),
        public_b58: bs58::encode(public_key.to_bytes()).into_string(),
    }
}

pub fn chacha_encrypt_dm(my_secret: Vec<u8>, their_public: Vec<u8>, plaintext: String) -> ResultWallet<String> {
    let my_sk = crypto_box::SecretKey::from_slice(&my_secret)
        .map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Invalid secret".into()))?;
    let their_pk = crypto_box::PublicKey::from_slice(&their_public)
        .map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Invalid public".into()))?;
    
    let box_algo = crypto_box::ChaChaBox::new(&their_pk, &my_sk);
    let mut nonce_bytes = [0u8; 24];
    rand::RngCore::fill_bytes(&mut rand::thread_rng(), &mut nonce_bytes);
    
    let ciphertext = box_algo.encrypt(&nonce_bytes.into(), plaintext.as_bytes())
        .map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Encrypt failed".into()))?;
        
    let mut concat = nonce_bytes.to_vec();
    concat.extend(ciphertext);
    Ok(bs58::encode(concat).into_string())
}

pub fn chacha_decrypt_dm(my_secret: Vec<u8>, their_public: Vec<u8>, ciphertext_b58: String) -> ResultWallet<String> {
    let my_sk = crypto_box::SecretKey::from_slice(&my_secret)
        .map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Invalid secret".into()))?;
    let their_pk = crypto_box::PublicKey::from_slice(&their_public)
        .map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Invalid public".into()))?;
        
    let cipher_bytes = bs58::decode(&ciphertext_b58).into_vec()
        .map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Invalid b58".into()))?;
    if cipher_bytes.len() < 24 {
        return Err(DarkfiWalletNativeError::NativeDrkUnavailable("Too short".into()));
    }
    
    let nonce_bytes: [u8; 24] = cipher_bytes[0..24].try_into().unwrap();
    let box_algo = crypto_box::ChaChaBox::new(&their_pk, &my_sk);
    
    let decrypted = box_algo.decrypt(&nonce_bytes.into(), &cipher_bytes[24..])
        .map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Decrypt failed".into()))?;
        
    String::from_utf8(decrypted).map_err(|_| DarkfiWalletNativeError::NativeDrkUnavailable("Invalid UTF8".into()))
}

uniffi::include_scaffolding!("darkfi_mobile_ffi");

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_config() -> DrkBootstrapConfig {
        DrkBootstrapConfig {
            network: "testnet".into(),
            mnemonic: (1..=22).map(|i| format!("word{i:04}")).collect(),
            wallet_db_path: "/tmp/wallet.db".into(),
            cache_path: "/tmp/cache".into(),
            wallet_pass: "pass".into(),
            darkfid_endpoint_url: "tcp://127.0.0.1:18345".into(),
            birthday_height: -1,
        }
    }

    #[test]
    fn validate_bootstrap_rejects_bad_network() {
        let mut cfg = sample_config();
        cfg.network = "invalid".into();
        assert!(matches!(
            validate_bootstrap(&cfg),
            Err(DarkfiWalletNativeError::InvalidBootstrapConfig)
        ));
    }

    #[test]
    fn validate_bootstrap_accepts_testnet_22_words() {
        assert!(validate_bootstrap(&sample_config()).is_ok());
    }

    #[test]
    fn validate_bootstrap_rejects_bad_mnemonic_length() {
        let mut cfg = sample_config();
        cfg.mnemonic = vec!["only".into(), "three".into(), "words".into()];
        assert!(matches!(
            validate_bootstrap(&cfg),
            Err(DarkfiWalletNativeError::InvalidBootstrapConfig)
        ));
    }

    #[test]
    fn validate_bootstrap_rejects_empty_wallet_pass() {
        let mut cfg = sample_config();
        cfg.wallet_pass.clear();
        assert!(matches!(
            validate_bootstrap(&cfg),
            Err(DarkfiWalletNativeError::InvalidBootstrapConfig)
        ));
    }
}
