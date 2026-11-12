//! Preflight: start Nym + darkirc, send one message to `#nighthawk`, exit.
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

struct Cb {
    hits: Arc<AtomicUsize>,
}

impl darkfi_mobile_ffi::DarkircEventCallback for Cb {
    fn on_message(
        &self,
        event_id: String,
        channel: String,
        nick: String,
        message: String,
        timestamp: u64,
        is_outgoing: bool,
    ) {
        self.hits.fetch_add(1, Ordering::SeqCst);
        eprintln!(
            "MSG channel={channel} nick={nick} outgoing={is_outgoing} ts={timestamp} id={event_id} text={message}"
        );
    }
}

fn main() {
    let hits = Arc::new(AtomicUsize::new(0));
    let cb = Box::new(Cb {
        hits: hits.clone(),
    });
    let store = "/tmp/nh-preflight/darkirc-store".to_string();
    let _ = std::fs::remove_dir_all(&store);
    std::fs::create_dir_all(&store).unwrap();

    let mode = std::env::args().nth(1).unwrap_or_else(|| "nym".into());
    let use_nym = mode != "direct";
    if use_nym {
        eprintln!("starting nym…");
        darkfi_mobile_ffi::start_nym_proxy("1080".into()).expect("start_nym_proxy");
        let nym_deadline = Instant::now() + Duration::from_secs(150);
        loop {
            let st = darkfi_mobile_ffi::nym_status();
            eprintln!("nym_status={st}");
            if st == "connected" || st == "reconnecting" {
                break;
            }
            if st == "failed" || Instant::now() > nym_deadline {
                eprintln!("FAIL nym bootstrap status={st}");
                std::process::exit(2);
            }
            thread::sleep(Duration::from_millis(500));
        }
    } else {
        eprintln!("starting direct…");
    }

    darkfi_mobile_ffi::start_darkirc(store, false, 9050, use_nym, 1080, Some(cb))
        .expect("start_darkirc");

    let connect_deadline = Instant::now() + Duration::from_secs(420);
    loop {
        let st = darkfi_mobile_ffi::darkirc_status();
        let phase = darkfi_mobile_ffi::darkirc_connection_phase();
        eprintln!("darkirc_status={st} phase={phase}");
        if st.contains("connected")
            || phase.contains("connected")
            || phase.contains("synced")
            || phase.contains("ready")
        {
            break;
        }
        if Instant::now() > connect_deadline {
            eprintln!("WARN darkirc connect timeout; sending anyway");
            break;
        }
        thread::sleep(Duration::from_secs(2));
    }

    let nick = format!("nh-preflight-{}", std::process::id() % 10_000);
    let msg = format!(
        "preflight ping {}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
    );
    eprintln!("sending to #nighthawk as {nick}: {msg}");
    match darkfi_mobile_ffi::send_chat_message("#nighthawk".into(), nick, msg) {
        Ok(()) => eprintln!("SEND_OK"),
        Err(e) => {
            eprintln!("SEND_ERR {e:?}");
            let _ = darkfi_mobile_ffi::stop_darkirc();
            darkfi_mobile_ffi::stop_nym_proxy();
            std::process::exit(3);
        }
    }

    let listen_until = Instant::now() + Duration::from_secs(30);
    while Instant::now() < listen_until {
        thread::sleep(Duration::from_secs(2));
        eprintln!(
            "status={} phase={} hits={}",
            darkfi_mobile_ffi::darkirc_status(),
            darkfi_mobile_ffi::darkirc_connection_phase(),
            hits.load(Ordering::SeqCst)
        );
    }

    let _ = darkfi_mobile_ffi::stop_darkirc();
    darkfi_mobile_ffi::stop_nym_proxy();
    eprintln!("DONE hits={}", hits.load(Ordering::SeqCst));
}
