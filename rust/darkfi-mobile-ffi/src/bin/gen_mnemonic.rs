fn main() {
    let phrase = darkfi_mobile_ffi::generate_darkfi_mnemonic();
    println!("Generated Seed Phrase: {}", phrase.join(" "));
}
