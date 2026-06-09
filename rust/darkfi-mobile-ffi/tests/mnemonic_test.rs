use darkfi_mobile_ffi::generate_darkfi_mnemonic;

#[test]
fn test_mnemonic() {
    let phrase = generate_darkfi_mnemonic();
    println!("PHRASE: {:?}", phrase);
    assert_eq!(phrase.len(), 22);
}
