//! Payment memo encoding limits (UTF-8 bytes in `MoneyNote::memo`).

pub const MAX_PAYMENT_MEMO_BYTES: usize = 512;

pub fn parse_payment_memo(memo: Option<&str>) -> Result<Option<Vec<u8>>, String> {
    let Some(text) = memo.map(str::trim).filter(|s| !s.is_empty()) else {
        return Ok(None);
    };

    if text.len() > MAX_PAYMENT_MEMO_BYTES {
        return Err(format!(
            "memo exceeds {MAX_PAYMENT_MEMO_BYTES} bytes (UTF-8 length {})",
            text.len()
        ));
    }

    Ok(Some(text.as_bytes().to_vec()))
}
