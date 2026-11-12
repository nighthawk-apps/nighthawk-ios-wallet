struct DummyCb;
impl darkfi_mobile_ffi::DarkircEventCallback for DummyCb {
    fn on_message(
        &self,
        _event_id: String,
        channel: String,
        nick: String,
        message: String,
        timestamp: u64,
        _is_outgoing: bool,
    ) {
        println!(
            "Message from {}: {} (channel: {}, time: {})",
            nick, message, channel, timestamp
        );
    }
}

fn main() {
    #[cfg(target_os = "android")]
    android_logger::init_once(
        android_logger::Config::default()
            .with_max_level(log::LevelFilter::Trace)
            .with_tag("darkfi-mobile-ffi"),
    );
    let cb = Box::new(DummyCb);
    // Clearnet by default; pass `tor <socks_port>` to exercise the SOCKS path.
    let args: Vec<String> = std::env::args().collect();
    let mode = args.get(1).map(|s| s.as_str()).unwrap_or("direct");
    let socks_port: u16 = args.get(2).and_then(|p| p.parse().ok()).unwrap_or(9050);
    let use_tor = mode == "tor";
    let use_nym = mode == "nym";
    println!("Starting darkirc (mode={mode}, socks_port={socks_port})...");
    let datastore = "/tmp/darkirc_test_store".to_string();
    std::fs::remove_dir_all(&datastore).ok();
    darkfi_mobile_ffi::start_darkirc(
        datastore,
        use_tor,
        socks_port,
        use_nym,
        if use_nym { socks_port } else { 1080 },
        Some(cb),
    )
    .unwrap();

    loop {
        std::thread::sleep(std::time::Duration::from_secs(1));
        println!("Status: {}", darkfi_mobile_ffi::darkirc_status());
    }
}
