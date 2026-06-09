//! In-process darkirc daemon for mobile.
//!
//! The darkirc daemon runs as a background thread inside the FFI library.
//! It connects to the DarkFi P2P network and syncs the event graph (DAG).
//! Messages are passed directly to the UI via UniFFI callbacks.
//!
//! Kept byte-for-byte and protocol-compatible with upstream `darkirc`
//! (`third_party/darkfi/bin/darkirc`) and at parity with the Android
//! `rust/darkfi-mobile-ffi` daemon.

use std::path::PathBuf;
use std::sync::atomic::{AtomicU8, Ordering};
use std::sync::Arc;

use darkfi_serial::{async_trait, deserialize_async_partial, serialize_async, SerialDecodable, SerialEncodable};
use smol::Executor;

use crate::{DarkfiWalletNativeError, DarkircEventCallback};

/// Daemon lifecycle states exposed to Swift via UniFFI.
const STATUS_NOT_RUNNING: u8 = 0;
const STATUS_STARTING: u8 = 1;
const STATUS_RUNNING: u8 = 2;
const STATUS_STOPPING: u8 = 3;
const STATUS_FAILED: u8 = 4;

/// Global daemon state (atomically updated).
static DAEMON_STATUS: AtomicU8 = AtomicU8::new(STATUS_NOT_RUNNING);

/// Global stop signal so we can shut down gracefully.
static STOP_SIGNAL: std::sync::LazyLock<smol::channel::Sender<()>> = std::sync::LazyLock::new(|| {
    let (tx, _) = smol::channel::bounded(1);
    tx
});

static STOP_RECEIVER: std::sync::LazyLock<smol::channel::Receiver<()>> =
    std::sync::LazyLock::new(|| {
        let (_, rx) = smol::channel::bounded(1);
        rx
    });

/// Global handles for sending messages
static EVENT_GRAPH: std::sync::LazyLock<smol::lock::RwLock<Option<darkfi::event_graph::EventGraphPtr>>> =
    std::sync::LazyLock::new(|| smol::lock::RwLock::new(None));
static P2P: std::sync::LazyLock<smol::lock::RwLock<Option<darkfi::net::P2pPtr>>> =
    std::sync::LazyLock::new(|| smol::lock::RwLock::new(None));

/// On-wire IRC PRIVMSG, byte-for-byte compatible with upstream `darkirc`
/// (`bin/darkirc/src/irc/mod.rs`). The leading `version` and `msg_type`
/// fields are part of the serialized DAG event content; omitting them
/// shifts every subsequent field and breaks deserialization of real
/// network events (the cause of missing public-channel messages).
#[derive(Clone, Debug, SerialEncodable, SerialDecodable)]
pub struct Privmsg {
    /// Wire-format version byte emitted by upstream `darkirc`.
    pub version: u8,
    /// Message-type discriminator emitted by upstream `darkirc`.
    pub msg_type: u8,
    /// Target channel (e.g. `#dev`).
    pub channel: String,
    /// Sender nickname.
    pub nick: String,
    /// Message body.
    pub msg: String,
}

/// Current upstream wire version emitted by `darkirc` clients.
const PRIVMSG_VERSION: u8 = 0;
/// Plaintext/standard message type emitted by `darkirc` clients.
const PRIVMSG_MSG_TYPE: u8 = 0;

impl Privmsg {
    pub fn new(channel: String, nick: String, msg: String) -> Self {
        Self { version: PRIVMSG_VERSION, msg_type: PRIVMSG_MSG_TYPE, channel, nick, msg }
    }
}

/// Initializes a `tracing` subscriber once so the darkfi `net`/`event_graph`
/// diagnostics (which log through the `tracing` facade) reach the iOS console.
///
/// Android bridges `tracing` into logcat via `android_logger`; on iOS the
/// default `fmt` subscriber writes to stdout, which Xcode surfaces in the
/// debug console. Without this, P2P/DAG-sync failures are invisible.
static LOGGING_INIT: std::sync::Once = std::sync::Once::new();

fn init_logging() {
    LOGGING_INIT.call_once(|| {
        // INFO surfaces the meaningful P2P/DAG milestones ("Connected seed",
        // "Got peer connection", "Static synced", version-exchange failures)
        // without the per-message DEBUG flood. Bump to `net=debug` when
        // diagnosing connection issues.
        let filter = tracing_subscriber::EnvFilter::new("info");
        let _ = tracing_subscriber::fmt()
            .with_env_filter(filter)
            .with_ansi(false)
            .with_target(true)
            .without_time()
            .try_init();
    });
}

/// Returns the current daemon status as a string.
pub fn darkirc_status() -> String {
    match DAEMON_STATUS.load(Ordering::Relaxed) {
        STATUS_NOT_RUNNING => "not_running",
        STATUS_STARTING => "starting",
        STATUS_RUNNING => "running",
        STATUS_STOPPING => "stopping",
        STATUS_FAILED => "failed",
        _ => "unknown",
    }
    .to_string()
}

/// Start the darkirc daemon on a background thread.
///
/// When `use_tor` is set, all P2P traffic is routed over darkfi's embedded
/// Tor transport (`tor://` onion seeds, dialled through in-process arti); the
/// arti data/cache live under `datastore_path/p2p/arti-*`. When false, the daemon
/// connects over clearnet `tcp+tls` seeds. This makes the UI's "Connected
/// (Tor)" indicator honest: it is only reachable when the node actually
/// completed an onion handshake and DAG sync.
pub fn start_darkirc(datastore_path: String, use_tor: bool, callback: Option<Box<dyn DarkircEventCallback>>) -> Result<(), DarkfiWalletNativeError> {
    let mut current = DAEMON_STATUS.load(Ordering::SeqCst);
    loop {
        if current == STATUS_RUNNING || current == STATUS_STARTING || current == STATUS_STOPPING {
            return Err(DarkfiWalletNativeError::NativeDrkUnavailable(
                format!("darkirc cannot start, current status: {}", darkirc_status()),
            ));
        }
        match DAEMON_STATUS.compare_exchange_weak(current, STATUS_STARTING, Ordering::SeqCst, Ordering::SeqCst) {
            Ok(_) => break,
            Err(x) => current = x,
        }
    }
    init_logging();

    let db_path = PathBuf::from(&datastore_path);
    let cb: Option<Arc<dyn DarkircEventCallback>> = callback.map(|b| Arc::from(b));

    std::thread::Builder::new()
        .name("darkirc".to_string())
        .spawn(move || {
            let ex = Arc::new(Executor::new());
            let ex_clone = ex.clone();

            let result = easy_parallel::Parallel::new()
                .each(0..4, |_| smol::block_on(ex_clone.run(smol::future::pending::<()>())))
                .finish(|| {
                    smol::block_on(async {
                        run_darkirc_daemon(db_path, use_tor, ex.clone(), cb).await
                    })
                })
                .1;

            match result {
                Ok(()) => {
                    DAEMON_STATUS.store(STATUS_NOT_RUNNING, Ordering::Relaxed);
                }
                Err(e) => {
                    tracing::error!("darkirc daemon failed: {e}");
                    DAEMON_STATUS.store(STATUS_FAILED, Ordering::Relaxed);
                }
            }
        })
        .map_err(|e| DarkfiWalletNativeError::NativeDrkUnavailable(
            format!("failed to spawn darkirc thread: {e}"),
        ))?;

    Ok(())
}

/// Stop the darkirc daemon gracefully.
pub fn stop_darkirc() -> Result<(), DarkfiWalletNativeError> {
    let mut current = DAEMON_STATUS.load(Ordering::SeqCst);
    loop {
        if current != STATUS_RUNNING {
            return Err(DarkfiWalletNativeError::NativeDrkUnavailable(
                format!("darkirc is not running (status: {})", darkirc_status()),
            ));
        }
        match DAEMON_STATUS.compare_exchange_weak(current, STATUS_STOPPING, Ordering::SeqCst, Ordering::SeqCst) {
            Ok(_) => break,
            Err(x) => current = x,
        }
    }

    let _ = STOP_SIGNAL.try_send(());
    Ok(())
}

/// Send a chat message natively.
///
/// Mirrors upstream `darkirc` (`bin/darkirc/src/irc/client.rs`): the event is
/// keyed by the current genesis timestamp (NOT the channel), its header is
/// inserted into the Header DAG before `dag_insert`, and the broadcast carries
/// an empty RLN blob (`vec![]`) because mobile clients have no RLN identity.
pub fn send_chat_message(channel: String, nick: String, message: String) -> Result<(), DarkfiWalletNativeError> {
    let current = DAEMON_STATUS.load(Ordering::Relaxed);
    if current != STATUS_RUNNING {
        return Err(DarkfiWalletNativeError::NativeDrkUnavailable(
            "darkirc daemon is not running".to_string(),
        ));
    }

    crate::block_on(async move {
        let eg_lock = EVENT_GRAPH.read().await;
        let p2p_lock = P2P.read().await;

        if let (Some(eg), Some(p2p)) = (&*eg_lock, &*p2p_lock) {
            let msg = Privmsg::new(channel.clone(), nick, message);

            let event = darkfi::event_graph::Event::new(serialize_async(&msg).await, eg).await;

            // The DAG is keyed by the current genesis timestamp, NOT the channel.
            // (`dag_insert` parses `dag_name` as a u64 timestamp; passing the
            // channel name here previously made every send fail.)
            let dag_name = eg.current_genesis.read().await.header.timestamp.to_string();

            // Upstream darkirc inserts the event header into the Header DAG
            // before `dag_insert`; `dag_insert` silently skips any event whose
            // header is absent from the header store, so this step is required
            // for the message to be stored, relayed, and broadcast.
            if let Err(e) = eg.header_dag_insert(vec![event.header.clone()], &dag_name).await {
                tracing::error!("Failed inserting new header to Header DAG: {}", e);
                return Err(DarkfiWalletNativeError::NativeDrkUnavailable(format!("header_dag_insert failed: {}", e)));
            }

            if let Err(e) = eg.dag_insert(&[event.clone()], &dag_name).await {
                tracing::error!("Failed inserting new event to DAG: {}", e);
                return Err(DarkfiWalletNativeError::NativeDrkUnavailable(format!("dag_insert failed: {}", e)));
            }

            // Empty RLN blob: mobile clients do not carry an RLN identity, which
            // matches upstream's non-RLN broadcast path (`EventPut(event, vec![])`).
            p2p.broadcast(&darkfi::event_graph::proto::EventPut(event, vec![])).await;
            Ok(())
        } else {
            Err(DarkfiWalletNativeError::NativeDrkUnavailable("EventGraph or P2P not initialized".to_string()))
        }
    })
}

/// The actual darkirc daemon loop. Runs until stopped or error.
async fn run_darkirc_daemon(
    datastore_path: PathBuf,
    use_tor: bool,
    ex: Arc<Executor<'static>>,
    callback: Option<Arc<dyn DarkircEventCallback>>,
) -> Result<(), String> {
    use darkfi::{
        event_graph::{proto::ProtocolEventGraph, EventGraph},
        net::{
            session::SESSION_DEFAULT,
            settings::{NetworkProfile, Settings},
            P2p,
        },
    };
    use sled_overlay::sled;
    use url::Url;

    // Create datastore
    std::fs::create_dir_all(&datastore_path).map_err(|e| format!("create datastore: {e}"))?;
    let sled_db = sled::open(&datastore_path).map_err(|e| format!("open sled: {e}"))?;

    // Seeds and the outbound transport profile are chosen by `use_tor`. Both
    // sets come straight from upstream `bin/darkirc/darkirc_config.toml`:
    //   - clearnet: the `tcp+tls` lilith seeds.
    //   - tor: the `tor://...onion` seeds, dialled through darkfi's embedded
    //     arti transport (gated by the `p2p-tor` cargo feature).
    // Seeds are used for peer discovery (fetch the address book, then
    // disconnect); real outbound connections are then opened to discovered
    // peers over the same active profile, so with the `tor` profile every
    // connection stays inside Tor.
    let (profile_name, seeds): (&str, Vec<Url>) = if use_tor {
        (
            "tor",
            vec![
                Url::parse("tor://g7fxelebievvpr27w7gt24lflptpw3jeeuvafovgliq5utdst6xyruyd.onion:25552").unwrap(),
                Url::parse("tor://yvklzjnfmwxhyodhrkpomawjcdvcaushsj6torjz2gyd7e25f3gfunyd.onion:25552").unwrap(),
            ],
        )
    } else {
        (
            "tcp+tls",
            vec![
                Url::parse("tcp+tls://lilith0.dark.fi:25551").unwrap(),
                Url::parse("tcp+tls://lilith1.dark.fi:25551").unwrap(),
            ],
        )
    };

    // The embedded arti client persists its directory cache + state under the
    // datastore so it survives restarts and lives inside the app sandbox.
    // darkfi threads this into the Tor dialer (see `net::connector` ->
    // `Dialer::new(.., datastore, ..)`). Harmless for the clearnet profile.
    let p2p_datastore = datastore_path.join("p2p");
    std::fs::create_dir_all(&p2p_datastore).map_err(|e| format!("create p2p datastore: {e}"))?;

    let mut p2p_settings = Settings {
        app_name: "darkirc".to_string(),
        app_version: semver::Version::parse("0.5.1").unwrap(),
        // The live darkirc network uses darkfi's DEFAULT magic bytes
        // ([0xd9, 0xef, 0xb6, 0x7d] == [217, 239, 182, 125]), confirmed by the
        // seed handshake (lilith0.dark.fi advertises this). The example
        // `darkirc_config.toml` ships [251, 229, 199, 181], but the deployed
        // seeds do NOT apply that override (they run with the default), so
        // using it caused every seed handshake to fail with "Magic bytes
        // mismatch" and the DAG never synced. This is also `MagicBytes::default`.
        magic_bytes: darkfi::net::settings::MagicBytes([217, 239, 182, 125]),
        seeds,
        peers: vec![],
        outbound_connections: 5,
        inbound_connections: 2,
        // We are a leaf client connecting to public seeds. Strict banning makes
        // a single odd frame from a seed permanently blacklist it (and the
        // blacklist is sticky for the process), which starved us of the only
        // reachable seed. Relaxed matches how seed-facing nodes behave.
        ban_policy: darkfi::net::settings::BanPolicy::Relaxed,
        p2p_datastore: Some(p2p_datastore.to_string_lossy().into_owned()),
        ..Settings::default()
    };

    // Tor circuits are slow to build, so use the longer upstream tor timeouts
    // for that profile; clearnet keeps the snappier values.
    let mut profile = if use_tor {
        NetworkProfile::tor_default()
    } else {
        let mut p = NetworkProfile::default();
        p.outbound_connect_timeout = 40;
        p.channel_handshake_timeout = 30;
        p
    };
    if use_tor {
        // Onion handshakes (bootstrap + circuit + version exchange) can exceed
        // the 65s tor default on mobile networks; give them headroom.
        profile.outbound_connect_timeout = 90;
        profile.channel_handshake_timeout = 75;
    }
    p2p_settings.profiles.insert(profile_name.to_string(), profile);
    p2p_settings.active_profiles = vec![profile_name.to_string()];

    let p2p = P2p::new(p2p_settings, ex.clone())
        .await
        .map_err(|e| format!("P2P init: {e}"))?;

    let replay_path = datastore_path.join("replay");
    std::fs::create_dir_all(&replay_path).map_err(|e| format!("create replay dir: {e}"))?;

    let event_graph = EventGraph::new(
        p2p.clone(),
        sled_db.clone(),
        replay_path.clone(),
        false, // replay_mode
        false, // fast_mode
        1,     // genesis_timestamp offset
        ex.clone(),
    )
    .await
    .map_err(|e| format!("EventGraph init: {e}"))?;

    let prune_task = event_graph.prune_task.get().unwrap();

    let event_graph_ = Arc::clone(&event_graph);
    let registry = p2p.protocol_registry();
    registry
        .register(SESSION_DEFAULT, move |channel, _| {
            let eg = event_graph_.clone();
            async move { ProtocolEventGraph::init(eg, channel).await.unwrap() }
        })
        .await;

    // Save globals
    *EVENT_GRAPH.write().await = Some(event_graph.clone());
    *P2P.write().await = Some(p2p.clone());

    p2p.clone().start().await.map_err(|e| format!("P2P start: {e}"))?;

    DAEMON_STATUS.store(STATUS_RUNNING, Ordering::Relaxed);
    tracing::info!(
        "darkirc daemon started over {} transport, syncing DAG...",
        if use_tor { "tor" } else { "tcp+tls" }
    );

    let dags_count = 8usize;
    let comms_timeout = 5u64;

    // Relay events
    let ev_sub = event_graph.event_pub.clone().subscribe().await;
    let cb_clone = callback.clone();
    let relay_task = ex.spawn(async move {
        loop {
            let ev = ev_sub.receive().await;
            if let Some(cb) = &cb_clone {
                if let Ok((privmsg, _)) = deserialize_async_partial::<Privmsg>(ev.content()).await {
                    cb.on_message(privmsg.channel, privmsg.nick, privmsg.msg, ev.header.timestamp);
                }
            }
        }
    });

    loop {
        if p2p.is_connected() {
            tracing::info!("darkirc daemon connected, waiting for static sync...");
            if let Err(_) = event_graph.static_sync().await {
                smol::future::race(
                    async { let _ = STOP_RECEIVER.recv().await; },
                    async { smol::Timer::after(std::time::Duration::from_secs(comms_timeout)).await; },
                ).await;
                continue;
            }
            tracing::info!("darkirc daemon static sync complete. Starting sync_selected...");
            if let Ok(()) = event_graph.sync_selected(dags_count, false).await {
                tracing::info!("darkirc daemon sync_selected complete. Fetching historical events...");
                let history = event_graph.order_events().await;
                tracing::info!("darkirc daemon fetched {} historical events", history.len());
                if let Some(cb) = &callback {
                    for ev in history {
                        if let Ok((privmsg, _)) = deserialize_async_partial::<Privmsg>(ev.content()).await {
                            cb.on_message(privmsg.channel, privmsg.nick, privmsg.msg, ev.header.timestamp);
                        }
                    }
                }
                break;
            }
        }
        smol::future::race(
            async { let _ = STOP_RECEIVER.recv().await; },
            async { smol::Timer::after(std::time::Duration::from_secs(comms_timeout)).await; },
        ).await;
        if DAEMON_STATUS.load(Ordering::Relaxed) == STATUS_STOPPING { break; }
    }

    let net_sub = p2p.hosts().subscribe_disconnect().await;
    loop {
        if DAEMON_STATUS.load(Ordering::Relaxed) == STATUS_STOPPING { break; }
        smol::future::race(
            async { let _ = net_sub.receive().await; },
            smol::future::race(
                async { let _ = STOP_RECEIVER.recv().await; },
                async { smol::Timer::after(std::time::Duration::from_secs(30)).await; },
            ),
        ).await;
    }

    p2p.stop().await;
    prune_task.stop().await;
    relay_task.cancel().await;

    // Clear globals
    *EVENT_GRAPH.write().await = None;
    *P2P.write().await = None;

    let _ = sled_db.flush_async().await;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use darkfi_serial::serialize_async;

    /// A public-channel PRIVMSG produced by upstream `darkirc` is serialized as
    /// `version | msg_type | channel | nick | msg`. This buffer is hand-encoded
    /// in that exact layout (u8 + VarInt-prefixed UTF-8 strings) so the test
    /// fails if the struct field order/count ever drifts from upstream.
    fn upstream_public_privmsg_bytes() -> Vec<u8> {
        let mut bytes = vec![0x00u8, 0x00u8]; // version = 0, msg_type = 0
        for s in ["#dev", "alice", "hello world"] {
            bytes.push(s.len() as u8); // VarInt length (single byte for <0xFD)
            bytes.extend_from_slice(s.as_bytes());
        }
        bytes
    }

    #[test]
    fn deserializes_upstream_public_channel_wire_format() {
        let bytes = upstream_public_privmsg_bytes();
        let (msg, consumed): (Privmsg, usize) =
            smol::block_on(deserialize_async_partial(&bytes)).expect("deserialize");

        assert_eq!(msg.version, 0);
        assert_eq!(msg.msg_type, 0);
        assert_eq!(msg.channel, "#dev");
        assert_eq!(msg.nick, "alice");
        assert_eq!(msg.msg, "hello world");
        assert_eq!(consumed, bytes.len());
    }

    #[test]
    fn serialized_output_matches_upstream_layout() {
        let msg = Privmsg::new("#dev".into(), "alice".into(), "hello world".into());
        let encoded = smol::block_on(serialize_async(&msg));
        // The first two bytes MUST be the version/msg_type prefix.
        assert_eq!(&encoded[..2], &[0x00, 0x00]);
        assert_eq!(encoded, upstream_public_privmsg_bytes());
    }

    #[test]
    fn round_trips_through_serialize_deserialize() {
        let original = Privmsg::new("#math".into(), "bob".into(), "2+2=4".into());
        let encoded = smol::block_on(serialize_async(&original));
        let (decoded, _): (Privmsg, usize) =
            smol::block_on(deserialize_async_partial(&encoded)).expect("deserialize");
        assert_eq!(decoded.version, original.version);
        assert_eq!(decoded.msg_type, original.msg_type);
        assert_eq!(decoded.channel, original.channel);
        assert_eq!(decoded.nick, original.nick);
        assert_eq!(decoded.msg, original.msg);
    }
}
