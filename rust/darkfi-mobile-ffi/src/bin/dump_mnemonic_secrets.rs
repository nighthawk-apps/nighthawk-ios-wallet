//! Dump bs58-encoded SecretKeys for `drk wallet import-secrets`.
//!
//! Usage:
//!   dump_mnemonic_secrets <mnemonics.txt>
//! where mnemonics.txt has one 22-word phrase per line.

use darkfi_mobile_ffi::mnemonic::secret_key_from_mnemonic;
use darkfi_serial::serialize_async;

fn words_from_phrase(phrase: &str) -> Vec<String> {
    phrase.split_whitespace().map(str::to_string).collect()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = std::env::args()
        .nth(1)
        .ok_or("usage: dump_mnemonic_secrets <mnemonics.txt>")?;
    let text = std::fs::read_to_string(&path)?;
    smol::block_on(async {
        for (i, line) in text.lines().filter(|l| !l.trim().is_empty()).enumerate() {
            let words = words_from_phrase(line);
            let secret = secret_key_from_mnemonic(&words).map_err(|e| e)?;
            let bytes = serialize_async(&secret).await;
            let encoded = bs58::encode(bytes).into_string();
            eprintln!("# wallet {i}");
            println!("{encoded}");
        }
        Ok::<(), String>(())
    })?;
    Ok(())
}
