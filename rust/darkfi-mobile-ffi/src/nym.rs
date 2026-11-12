//! In-process Nym mixnet SOCKS5 proxy for iOS and Android.
//!
//! Same transport as zkool2: a shared `nym_smolmix::Tunnel` sends TCP through
//! the mixnet and exits at an IPR gateway. Hostnames resolve over the tunnel
//! (DNS-over-HTTPS to 1.1.1.1, then DNS on port 53), so server names never
//! reach the local resolver. The mixnet client is ephemeral and needs no
//! bandwidth credential.
//!
//! The proxy speaks SOCKS5 on localhost like the Arti proxy in `tor.rs`, so
//! the lightwalletd client routes through it unchanged.
//!
//! Status is derived from the actual tunnel bootstrap: it never reports
//! `Connected` unless a tunnel came up. Transport failures discard the tunnel
//! and the next connection bootstraps a fresh one.

use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::sync::atomic::{AtomicBool, AtomicU8, Ordering};
use std::sync::Mutex as StdMutex;
use std::time::{Duration, Instant};

use hickory_proto::op::{Message, Query};
use hickory_proto::rr::{Name, RData, RecordType};
use nym_smolmix::{TcpStream as MixTcpStream, Tunnel};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::Mutex;

/// Default localhost SOCKS5 port for the Nym proxy.
pub const DEFAULT_NYM_SOCKS_PORT: u16 = 1080;

/// Per-attempt DNS query timeout (a fresh socket is used for each attempt).
const DNS_TIMEOUT: Duration = Duration::from_secs(15);
/// Public resolvers tried in turn through the mixnet, so one slow resolver or
/// exit path does not fail the lookup (and tear down the tunnel).
const DNS_RESOLVERS: [[u8; 4]; 3] = [[1, 1, 1, 1], [9, 9, 9, 9], [8, 8, 8, 8]];
/// A tunnel that recently proved healthy is not probed again for this long.
const HEALTH_PROBE_INTERVAL: Duration = Duration::from_secs(30);
/// How long a resolved address may be reused without a new lookup.
const DNS_TTL: Duration = Duration::from_secs(300);
/// Give up on a TCP connect through the mixnet after this long.
const TCP_CONNECT_TIMEOUT: Duration = Duration::from_secs(30);
/// Give up on tunnel bootstrap after this long. The bootstrap holds the
/// tunnel lock, so a hang here would otherwise block every caller forever.
const BOOTSTRAP_TIMEOUT: Duration = Duration::from_secs(90);

const NYM_STOPPED: u8 = 0;
const NYM_BOOTSTRAPPING: u8 = 1;
const NYM_CONNECTED: u8 = 2;
const NYM_FAILED: u8 = 3;

static NYM_STATE: AtomicU8 = AtomicU8::new(NYM_STOPPED);
static NYM_STOP_REQUESTED: AtomicBool = AtomicBool::new(false);
/// Set while a replacement tunnel bootstraps after the previous one failed.
static NYM_REBUILDING: AtomicBool = AtomicBool::new(false);
/// Generation and time of the last proof that the tunnel carries traffic.
static LAST_HEALTHY: StdMutex<Option<(u64, Instant)>> = StdMutex::new(None);

struct TunnelSlot {
    tunnel: Option<(u64, Tunnel)>,
    next_gen: u64,
}

static TUNNEL: Mutex<TunnelSlot> = Mutex::const_new(TunnelSlot {
    tunnel: None,
    next_gen: 0,
});

static DNS_CACHE: StdMutex<Option<HashMap<String, (IpAddr, Instant)>>> = StdMutex::new(None);

/// Cap simultaneous mixnet dials. A burst of seed and peer lookups stalls the
/// gateway bandwidth claim, and then every connect times out.
static DIAL_SLOTS: tokio::sync::Semaphore = tokio::sync::Semaphore::const_new(1);

/// Start the in-process Nym SOCKS proxy on the given port.
///
/// Returns `Ok(true)` when a new bootstrap was kicked off, `Ok(false)` when a
/// proxy is already running or bootstrapping. Bootstrap proceeds on a
/// background thread; poll [`is_nym_running`] to observe it.
pub fn start_nym_proxy(socks_port: u16) -> Result<bool, crate::DarkfiWalletNativeError> {
    #[cfg(feature = "darkirc")]
    crate::darkirc_daemon::init_logging();
    let _ = rustls::crypto::ring::default_provider().install_default();

    // A pending stop is still winding down the previous proxy; let it exit
    // so this start is not mistaken for a duplicate.
    let deadline = Instant::now() + Duration::from_secs(3);
    while NYM_STOP_REQUESTED.load(Ordering::SeqCst)
        && !matches!(NYM_STATE.load(Ordering::SeqCst), NYM_STOPPED | NYM_FAILED)
        && Instant::now() < deadline
    {
        std::thread::sleep(Duration::from_millis(50));
    }

    if NYM_STATE
        .compare_exchange(
            NYM_STOPPED,
            NYM_BOOTSTRAPPING,
            Ordering::SeqCst,
            Ordering::SeqCst,
        )
        .is_err()
    {
        if NYM_STATE.load(Ordering::SeqCst) == NYM_FAILED {
            NYM_STATE.store(NYM_BOOTSTRAPPING, Ordering::SeqCst);
        } else {
            return Ok(false);
        }
    }

    NYM_STOP_REQUESTED.store(false, Ordering::SeqCst);

    std::thread::Builder::new()
        .name("nym-proxy".into())
        .spawn(move || {
            let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                tokio::runtime::Builder::new_multi_thread()
                    .worker_threads(4)
                    .thread_name("nym-proxy-rt")
                    .enable_all()
                    .build()
                    .map_err(|e| format!("nym runtime: {e}"))?
                    .block_on(run_socks_proxy(socks_port))
            }));
            match result {
                Ok(Ok(())) => NYM_STATE.store(NYM_STOPPED, Ordering::SeqCst),
                Ok(Err(e)) => {
                    tracing::error!("nym proxy exited with error: {e}");
                    NYM_STATE.store(NYM_FAILED, Ordering::SeqCst);
                }
                Err(payload) => {
                    let msg = payload
                        .downcast_ref::<&str>()
                        .map(|s| s.to_string())
                        .or_else(|| payload.downcast_ref::<String>().cloned())
                        .unwrap_or_else(|| "unknown panic".into());
                    tracing::error!("nym proxy thread panicked: {msg}");
                    NYM_STATE.store(NYM_FAILED, Ordering::SeqCst);
                }
            }
        })
        .map_err(|e| {
            NYM_STATE.store(NYM_FAILED, Ordering::SeqCst);
            crate::DarkfiWalletNativeError::NativeDrkUnavailable(format!(
                "failed to spawn nym thread: {e}"
            ))
        })?;

    Ok(true)
}

/// Request the Nym SOCKS proxy to stop. The accept loop exits on its next
/// iteration, shuts the tunnel down, and resets the state to `Stopped`.
///
/// If bootstrap already failed and the proxy thread has exited, clear the
/// sticky `failed` status immediately — there is no thread left to do it.
pub fn stop_nym_proxy() {
    NYM_STOP_REQUESTED.store(true, Ordering::SeqCst);
    let _ = NYM_STATE.compare_exchange(
        NYM_FAILED,
        NYM_STOPPED,
        Ordering::SeqCst,
        Ordering::SeqCst,
    );
}

/// Whether the mixnet tunnel genuinely came up and the proxy is accepting.
pub fn is_nym_running() -> bool {
    NYM_STATE.load(Ordering::SeqCst) == NYM_CONNECTED
}

/// Proxy lifecycle for UI progress: `stopped` | `bootstrapping` | `connected` |
/// `reconnecting` (a failed tunnel is being replaced) | `failed`.
pub fn nym_status() -> String {
    match NYM_STATE.load(Ordering::SeqCst) {
        NYM_BOOTSTRAPPING => "bootstrapping",
        NYM_CONNECTED if NYM_REBUILDING.load(Ordering::SeqCst) => "reconnecting",
        NYM_CONNECTED => "connected",
        NYM_FAILED => "failed",
        _ => "stopped",
    }
    .to_string()
}

/// Block until the Nym tunnel is up (or `timeout` elapses / bootstrap failed).
pub fn wait_until_running(timeout: Duration) -> Result<(), crate::DarkfiWalletNativeError> {
    let deadline = Instant::now() + timeout;
    loop {
        if NYM_STOP_REQUESTED.load(Ordering::SeqCst) {
            return Err(crate::DarkfiWalletNativeError::NativeDrkUnavailable(
                "Nym mixnet proxy was stopped".into(),
            ));
        }
        match NYM_STATE.load(Ordering::SeqCst) {
            NYM_CONNECTED => return Ok(()),
            NYM_FAILED => {
                return Err(crate::DarkfiWalletNativeError::NativeDrkUnavailable(
                    "Nym mixnet bootstrap failed".into(),
                ));
            }
            NYM_STOPPED => {
                return Err(crate::DarkfiWalletNativeError::NativeDrkUnavailable(
                    "Nym mixnet proxy is not running".into(),
                ));
            }
            _ => {
                if Instant::now() >= deadline {
                    return Err(crate::DarkfiWalletNativeError::NativeDrkUnavailable(
                        "Timed out waiting for Nym mixnet bootstrap".into(),
                    ));
                }
                std::thread::sleep(Duration::from_millis(250));
            }
        }
    }
}

/// Bootstrap the tunnel and serve SOCKS5 CONNECT requests until stopped.
async fn run_socks_proxy(socks_port: u16) -> Result<(), String> {
    // Bind before bootstrap so readiness probes see a listening socket while
    // the mixnet client comes up (same reason as the Arti proxy).
    let listener = TcpListener::bind(("127.0.0.1", socks_port))
        .await
        .map_err(|e| format!("SOCKS bind on 127.0.0.1:{socks_port} failed: {e}"))?;
    tracing::info!("nym SOCKS bound on 127.0.0.1:{socks_port}; bootstrapping mixnet tunnel...");

    // A stop (e.g. the user continuing without Nym) abandons a slow bootstrap.
    // The directory fetch times out often on mobile; one failure used to kill
    // the proxy for the whole session, so DarkIRC never got a tunnel.
    let mut bootstrap_err = String::new();
    for attempt in 0..3 {
        if NYM_STOP_REQUESTED.load(Ordering::SeqCst) {
            tracing::info!("nym bootstrap cancelled by stop request");
            return Ok(());
        }
        match get_tunnel().await {
            Ok(_) => {
                bootstrap_err.clear();
                break;
            }
            Err(e) => {
                bootstrap_err = e;
                tracing::warn!("nym tunnel bootstrap failed (attempt {attempt}): {bootstrap_err}");
                tokio::select! {
                    _ = tokio::time::sleep(Duration::from_secs(2)) => {}
                    _ = wait_for_stop() => {
                        tracing::info!("nym bootstrap cancelled by stop request");
                        return Ok(());
                    }
                }
            }
        }
    }
    if !bootstrap_err.is_empty() {
        return Err(bootstrap_err);
    }
    NYM_STATE.store(NYM_CONNECTED, Ordering::SeqCst);
    tracing::info!("nym SOCKS proxy ready on 127.0.0.1:{socks_port}");

    while !NYM_STOP_REQUESTED.load(Ordering::SeqCst) {
        let accepted = tokio::select! {
            r = listener.accept() => r,
            _ = tokio::time::sleep(Duration::from_secs(1)) => continue,
        };
        match accepted {
            Ok((stream, _)) => {
                tokio::spawn(async move {
                    if let Err(e) = handle_socks_conn(stream).await {
                        // Info, not debug: a failed dial is why DarkIRC stays on
                        // "waiting for peers" after the tunnel itself is up.
                        tracing::warn!("nym SOCKS connection closed: {e}");
                    }
                });
            }
            Err(e) => tracing::warn!("nym SOCKS accept error: {e}"),
        }
    }

    let mut slot = TUNNEL.lock().await;
    if let Some((_, tunnel)) = slot.tunnel.take() {
        tunnel.shutdown().await;
    }
    clear_dns_cache();
    Ok(())
}

async fn wait_for_stop() {
    while !NYM_STOP_REQUESTED.load(Ordering::SeqCst) {
        tokio::time::sleep(Duration::from_millis(250)).await;
    }
}

/// Minimal SOCKS5 CONNECT handler: "no authentication", read the target,
/// dial it through the mixnet, and pipe bytes both ways.
async fn handle_socks_conn(mut inbound: TcpStream) -> Result<(), String> {
    let mut head = [0u8; 2];
    inbound
        .read_exact(&mut head)
        .await
        .map_err(|e| e.to_string())?;
    if head[0] != 0x05 {
        return Err("not a SOCKS5 greeting".into());
    }
    let mut methods = vec![0u8; head[1] as usize];
    inbound
        .read_exact(&mut methods)
        .await
        .map_err(|e| e.to_string())?;
    inbound
        .write_all(&[0x05, 0x00])
        .await
        .map_err(|e| e.to_string())?;

    let mut req = [0u8; 4];
    inbound
        .read_exact(&mut req)
        .await
        .map_err(|e| e.to_string())?;
    if req[0] != 0x05 {
        return Err("bad SOCKS5 request version".into());
    }
    if req[1] != 0x01 {
        let _ = inbound.write_all(&socks_reply(0x07)).await;
        return Err("unsupported SOCKS command".into());
    }

    let host: String = match req[3] {
        0x01 => {
            let mut addr = [0u8; 4];
            inbound
                .read_exact(&mut addr)
                .await
                .map_err(|e| e.to_string())?;
            std::net::Ipv4Addr::from(addr).to_string()
        }
        0x03 => {
            let mut len = [0u8; 1];
            inbound
                .read_exact(&mut len)
                .await
                .map_err(|e| e.to_string())?;
            let mut domain = vec![0u8; len[0] as usize];
            inbound
                .read_exact(&mut domain)
                .await
                .map_err(|e| e.to_string())?;
            String::from_utf8(domain).map_err(|e| e.to_string())?
        }
        0x04 => {
            let mut addr = [0u8; 16];
            inbound
                .read_exact(&mut addr)
                .await
                .map_err(|e| e.to_string())?;
            std::net::Ipv6Addr::from(addr).to_string()
        }
        other => {
            let _ = inbound.write_all(&socks_reply(0x08)).await;
            return Err(format!("unsupported SOCKS atyp {other}"));
        }
    };
    let mut port_bytes = [0u8; 2];
    inbound
        .read_exact(&mut port_bytes)
        .await
        .map_err(|e| e.to_string())?;
    let port = u16::from_be_bytes(port_bytes);

    // Onion services are only reachable over Tor; never fall back to clearnet.
    if host.to_ascii_lowercase().ends_with(".onion") {
        let _ = inbound.write_all(&socks_reply(0x04)).await;
        return Err(format!(
            "{host} is a Tor onion address; Nym cannot reach it"
        ));
    }

    let mut outbound = match nym_connect(&host, port).await {
        Ok(s) => s,
        Err(e) => {
            let _ = inbound.write_all(&socks_reply(0x04)).await;
            return Err(format!("Nym connect to {host}:{port} failed: {e}"));
        }
    };
    inbound
        .write_all(&socks_reply(0x00))
        .await
        .map_err(|e| e.to_string())?;

    tokio::io::copy_bidirectional(&mut inbound, &mut outbound)
        .await
        .map_err(|e| e.to_string())?;
    Ok(())
}

/// SOCKS5 reply with the given status and a dummy bound address (0.0.0.0:0).
fn socks_reply(status: u8) -> [u8; 10] {
    [0x05, status, 0x00, 0x01, 0, 0, 0, 0, 0, 0]
}

/// `Tunnel::build` resolves an exit before the gateway will forward packets.
/// DarkIRC must not dial until one TCP connect through that exit succeeds.
async fn wait_for_mixnet_traffic(tunnel: &Tunnel) -> Result<(), String> {
    let mut last = String::from("no probe");
    for attempt in 0..3 {
        if NYM_STOP_REQUESTED.load(Ordering::SeqCst) {
            return Err("Nym mixnet proxy was stopped".into());
        }
        let probe = tokio::time::timeout(
            Duration::from_secs(20),
            tunnel.tcp_connect(SocketAddr::from((DNS_RESOLVERS[0], 80))),
        )
        .await;
        match probe {
            Ok(Ok(_)) => return Ok(()),
            Ok(Err(e)) => last = e.to_string(),
            Err(_) => last = "timed out".into(),
        }
        tracing::warn!("nym traffic probe failed (attempt {attempt}): {last}");
        tokio::time::sleep(Duration::from_secs(2)).await;
    }
    Err(format!(
        "Nym mixnet tunnel is up but not carrying traffic: {last}"
    ))
}

/// The shared tunnel, bootstrapping one if none is cached. The lock is held
/// during bootstrap so concurrent callers wait for the same tunnel.
async fn get_tunnel() -> Result<(u64, Tunnel), String> {
    let slot = TUNNEL.lock().await;
    if let Some((gen, tunnel)) = &slot.tunnel {
        return Ok((*gen, tunnel.clone()));
    }
    tracing::info!("bootstrapping Nym mixnet tunnel");
    let start = Instant::now();
    NYM_REBUILDING.store(slot.next_gen > 0, Ordering::SeqCst);
    let built = tokio::time::timeout(BOOTSTRAP_TIMEOUT, Tunnel::builder().build()).await;
    NYM_REBUILDING.store(false, Ordering::SeqCst);
    let tunnel = built
        .map_err(|_| "Nym mixnet tunnel bootstrap timed out".to_string())?
        .map_err(|e| format!("failed to bootstrap Nym mixnet tunnel: {e}"))?;
    // Drop the lock before the probe. Holding it across `tcp_connect` on the
    // small proxy runtime kept the bridge from running, so the probe always
    // timed out even when the exit was fine.
    drop(slot);
    if let Err(e) = wait_for_mixnet_traffic(&tunnel).await {
        tracing::warn!("discarding Nym tunnel that is not carrying traffic: {e}");
        tokio::spawn(async move { tunnel.shutdown().await });
        return Err(e);
    }
    tracing::info!("Nym mixnet tunnel ready in {:?}", start.elapsed());
    let mut slot = TUNNEL.lock().await;
    if let Some((gen, existing)) = &slot.tunnel {
        let gen = *gen;
        let existing = existing.clone();
        tokio::spawn(async move { tunnel.shutdown().await });
        return Ok((gen, existing));
    }
    let gen = slot.next_gen;
    slot.next_gen += 1;
    slot.tunnel = Some((gen, tunnel.clone()));
    mark_healthy(gen);
    Ok((gen, tunnel))
}

/// Discard the cached tunnel if it is still generation `gen`, so the next
/// call bootstraps a fresh one. The stale tunnel shuts down in the background.
async fn invalidate_tunnel(gen: u64) {
    let mut slot = TUNNEL.lock().await;
    if matches!(&slot.tunnel, Some((g, _)) if *g == gen) {
        tracing::warn!("Nym tunnel failed; discarding it and clearing the DNS cache");
        if let Some((_, tunnel)) = slot.tunnel.take() {
            tokio::spawn(async move { tunnel.shutdown().await });
        }
        clear_dns_cache();
    }
}

/// Open a TCP stream to (host, port) through the mixnet.
///
/// A failed connect only discards the shared tunnel when a health probe shows
/// the tunnel itself is dead: P2P callers routinely dial offline peers, and
/// rebuilding on each of those would drop every other live connection.
async fn nym_connect(host: &str, port: u16) -> Result<MixTcpStream, String> {
    let _permit = DIAL_SLOTS
        .acquire()
        .await
        .map_err(|e| format!("nym dial slot: {e}"))?;
    let (gen, tunnel) = get_tunnel().await?;

    let ip = match resolve_over_nym(&tunnel, host).await {
        Ok(Some(ip)) => ip,
        Ok(None) => return Err(format!("no A record for {host} from mixnet DNS")),
        Err(e) => {
            // A lookup timeout is not proof the mixnet is dead. The health
            // probe was false-failing while the other seed handshake was in
            // flight, and discarding the tunnel aborted that handshake
            // ("Channel stopped"), so darkirc never left waiting_for_peers.
            return Err(e);
        }
    };

    let err = match tokio::time::timeout(
        TCP_CONNECT_TIMEOUT,
        tunnel.tcp_connect(SocketAddr::new(ip, port)),
    )
    .await
    {
        Ok(Ok(stream)) => {
            mark_healthy(gen);
            return Ok(stream);
        }
        Ok(Err(e)) => format!("mixnet TCP connect to {host}:{port} failed: {e}"),
        Err(_) => format!("mixnet TCP connect to {host}:{port} timed out"),
    };
    if !tunnel_is_healthy(gen, &tunnel).await {
        invalidate_tunnel(gen).await;
    }
    Err(err)
}

fn mark_healthy(gen: u64) {
    if let Ok(mut last) = LAST_HEALTHY.lock() {
        *last = Some((gen, Instant::now()));
    }
}

/// Whether tunnel `gen` still carries traffic: recently proven, or a TCP
/// connect through the mixnet succeeds.
///
/// UDP DNS to port 53 blackholes on Nym exits. Using that as the health
/// probe discarded tunnels that were already carrying the darkirc seed
/// handshake, which left the client on "waiting for peers".
async fn tunnel_is_healthy(gen: u64, tunnel: &Tunnel) -> bool {
    let recent = LAST_HEALTHY
        .lock()
        .ok()
        .and_then(|l| *l)
        .is_some_and(|(g, at)| g == gen && at.elapsed() < HEALTH_PROBE_INTERVAL);
    if recent {
        return true;
    }
    let resolver = DNS_RESOLVERS[0];
    for port in [443u16, 53] {
        let probe = tokio::time::timeout(
            DNS_TIMEOUT,
            tunnel.tcp_connect(SocketAddr::from((resolver, port))),
        );
        if matches!(probe.await, Ok(Ok(_))) {
            mark_healthy(gen);
            return true;
        }
    }
    false
}

/// Resolve `host` through the mixnet unless it is an IP literal or freshly
/// cached. `Ok(None)` means the DNS server answered without an A record
/// (tunnel healthy, name unresolvable); `Err` is a transport failure.
async fn resolve_over_nym(tunnel: &Tunnel, host: &str) -> Result<Option<IpAddr>, String> {
    if let Ok(ip) = host.parse::<IpAddr>() {
        return Ok(Some(ip));
    }
    if let Some(ip) = dns_cache_get(host) {
        return Ok(Some(ip));
    }

    let mut last_err = String::new();
    // Port 53 through Nym exits often never answers, while 443 does. Resolve
    // with DNS-over-HTTPS before falling back to classic DNS.
    match dns_query_doh(tunnel, host).await {
        Ok(answer) => {
            if let Some(ip) = answer {
                dns_cache_put(host, ip);
            }
            return Ok(answer);
        }
        Err(e) => {
            tracing::warn!("mixnet DoH lookup for {host} failed: {e}");
            last_err = e;
        }
    }

    // Mixnet UDP to public resolvers often blackholes while TCP to the same
    // resolver still works. Try DNS-over-TCP first so a seed dial is not
    // stuck behind three 8s UDP timeouts.
    for (attempt, resolver) in DNS_RESOLVERS.iter().take(2).enumerate() {
        let query = tokio::time::timeout(DNS_TIMEOUT, dns_query_tcp(tunnel, host, *resolver))
            .await
            .map_err(|_| format!("mixnet TCP DNS lookup for {host} timed out"))
            .and_then(|r| r);
        match query {
            Ok(answer) => {
                if let Some(ip) = answer {
                    dns_cache_put(host, ip);
                }
                return Ok(answer);
            }
            Err(e) => {
                tracing::warn!("mixnet TCP DNS lookup for {host} failed (attempt {attempt}): {e}");
                last_err = e;
            }
        }
    }

    for (attempt, resolver) in DNS_RESOLVERS.iter().enumerate() {
        let query = tokio::time::timeout(DNS_TIMEOUT, dns_query(tunnel, host, *resolver))
            .await
            .map_err(|_| format!("mixnet DNS lookup for {host} timed out"))
            .and_then(|r| r);
        match query {
            Ok(answer) => {
                if let Some(ip) = answer {
                    dns_cache_put(host, ip);
                }
                return Ok(answer);
            }
            Err(e) => {
                tracing::warn!("mixnet DNS lookup for {host} failed (attempt {attempt}): {e}");
                last_err = e;
            }
        }
    }
    Err(last_err)
}

/// DNS-over-HTTPS to 1.1.1.1:443. Nym exits often drop port 53 while 443
/// still connects, which is why seed dials died in "mixnet DNS lookup timed out"
/// after the tunnel itself was healthy.
async fn dns_query_doh(tunnel: &Tunnel, host: &str) -> Result<Option<IpAddr>, String> {
    use std::sync::Arc;

    use rustls_platform_verifier::BuilderVerifierExt;
    use tokio_rustls::TlsConnector;

    let tcp = tokio::time::timeout(
        DNS_TIMEOUT,
        tunnel.tcp_connect(SocketAddr::from((DNS_RESOLVERS[0], 443))),
    )
    .await
    .map_err(|_| "mixnet DoH connect timed out".to_string())?
    .map_err(|e| format!("mixnet DoH connect failed: {e}"))?;

    let config = rustls::ClientConfig::builder()
        .with_platform_verifier()
        .map_err(|e| format!("doh tls config: {e}"))?
        .with_no_client_auth();
    let name = rustls::pki_types::ServerName::try_from("one.one.one.one")
        .map_err(|e| format!("doh sni: {e}"))?
        .to_owned();
    let mut tls = TlsConnector::from(Arc::new(config))
        .connect(name, tcp)
        .await
        .map_err(|e| format!("mixnet DoH tls failed: {e}"))?;

    let query = dns_query_bytes(host)?;
    let header = format!(
        "POST /dns-query HTTP/1.1\r\n\
         Host: one.one.one.one\r\n\
         Accept: application/dns-message\r\n\
         Content-Type: application/dns-message\r\n\
         Content-Length: {}\r\n\
         Connection: close\r\n\r\n",
        query.len()
    );
    tls.write_all(header.as_bytes())
        .await
        .map_err(|e| e.to_string())?;
    tls.write_all(&query).await.map_err(|e| e.to_string())?;

    let mut buf = Vec::new();
    let mut tmp = [0u8; 1500];
    loop {
        let n = tokio::time::timeout(DNS_TIMEOUT, tls.read(&mut tmp))
            .await
            .map_err(|_| "mixnet DoH read timed out".to_string())?
            .map_err(|e| e.to_string())?;
        if n == 0 {
            break;
        }
        buf.extend_from_slice(&tmp[..n]);
        match http_dns_body(&buf)? {
            Some(_) => break,
            None => {}
        }
        if buf.len() > 16_384 {
            return Err("mixnet DoH response too large".into());
        }
    }
    let body = http_dns_body(&buf)?.ok_or_else(|| "truncated mixnet DoH response".to_string())?;
    let response = Message::from_vec(body).map_err(|e| e.to_string())?;
    Ok(first_a_record(&response))
}

/// `Ok(None)` until the headers and a full body are buffered. Non-200 is an error.
fn http_dns_body(buf: &[u8]) -> Result<Option<&[u8]>, String> {
    let Some(sep) = buf.windows(4).position(|w| w == b"\r\n\r\n") else {
        return Ok(None);
    };
    let header = std::str::from_utf8(&buf[..sep]).map_err(|e| e.to_string())?;
    let status_ok = header.starts_with("HTTP/1.1 200") || header.starts_with("HTTP/1.0 200");
    if !status_ok {
        let line = header.lines().next().unwrap_or(header);
        return Err(format!("mixnet DoH {line}"));
    }
    let len = header
        .lines()
        .find_map(|line| {
            let (name, value) = line.split_once(':')?;
            name.eq_ignore_ascii_case("content-length")
                .then(|| value.trim().parse::<usize>().ok())
                .flatten()
        })
        .ok_or_else(|| "mixnet DoH response has no content-length".to_string())?;
    let body = &buf[sep + 4..];
    if body.len() < len {
        return Ok(None);
    }
    Ok(Some(&body[..len]))
}

/// One DNS A query to `resolver` over a fresh tunnel UDP socket.
async fn dns_query(
    tunnel: &Tunnel,
    host: &str,
    resolver: [u8; 4],
) -> Result<Option<IpAddr>, String> {
    let udp = tunnel.udp_socket().await.map_err(|e| e.to_string())?;
    let bytes = dns_query_bytes(host)?;
    udp.send_to(&bytes, SocketAddr::from((resolver, 53)))
        .await
        .map_err(|e| e.to_string())?;
    let mut buf = [0u8; 1500];
    let (len, _src) = udp.recv_from(&mut buf).await.map_err(|e| e.to_string())?;
    let response = Message::from_vec(&buf[..len]).map_err(|e| e.to_string())?;
    Ok(first_a_record(&response))
}

/// DNS over TCP (RFC 1035 length prefix) through the mixnet. Used when UDP
/// to the resolver does not return, which is common on Nym IP exits.
async fn dns_query_tcp(
    tunnel: &Tunnel,
    host: &str,
    resolver: [u8; 4],
) -> Result<Option<IpAddr>, String> {
    let mut tcp = tunnel
        .tcp_connect(SocketAddr::from((resolver, 53)))
        .await
        .map_err(|e| e.to_string())?;
    let bytes = dns_query_bytes(host)?;
    if bytes.len() > u16::MAX as usize {
        return Err("DNS query too large".into());
    }
    tcp.write_all(&(bytes.len() as u16).to_be_bytes())
        .await
        .map_err(|e| e.to_string())?;
    tcp.write_all(&bytes).await.map_err(|e| e.to_string())?;
    let mut len_buf = [0u8; 2];
    tcp.read_exact(&mut len_buf)
        .await
        .map_err(|e| e.to_string())?;
    let n = u16::from_be_bytes(len_buf) as usize;
    if n == 0 || n > 4096 {
        return Err(format!("DNS TCP response length {n}"));
    }
    let mut buf = vec![0u8; n];
    tcp.read_exact(&mut buf).await.map_err(|e| e.to_string())?;
    let response = Message::from_vec(&buf).map_err(|e| e.to_string())?;
    Ok(first_a_record(&response))
}

fn dns_query_bytes(host: &str) -> Result<Vec<u8>, String> {
    let mut query = Message::query();
    query.metadata.recursion_desired = true;
    let name = Name::from_ascii(host).map_err(|e| e.to_string())?;
    query.add_query(Query::query(name, RecordType::A));
    query.to_vec().map_err(|e| e.to_string())
}

fn first_a_record(msg: &Message) -> Option<IpAddr> {
    msg.answers.iter().find_map(|record| match &record.data {
        RData::A(a) => Some(IpAddr::V4(a.0)),
        _ => None,
    })
}

fn dns_cache_get(host: &str) -> Option<IpAddr> {
    let cache = DNS_CACHE.lock().ok()?;
    let (ip, at) = cache.as_ref()?.get(host)?;
    (at.elapsed() < DNS_TTL).then_some(*ip)
}

fn dns_cache_put(host: &str, ip: IpAddr) {
    if let Ok(mut cache) = DNS_CACHE.lock() {
        cache
            .get_or_insert_with(HashMap::new)
            .insert(host.to_string(), (ip, Instant::now()));
    }
}

fn clear_dns_cache() {
    if let Ok(mut cache) = DNS_CACHE.lock() {
        *cache = None;
    }
}

#[cfg(test)]
mod tests {
    use std::net::Ipv4Addr;
    use std::str::FromStr;

    use hickory_proto::op::{Message, MessageType, OpCode, Query};
    use hickory_proto::rr::{rdata, Name, RData, Record, RecordType};

    use super::*;

    #[test]
    fn first_a_record_skips_cname_and_picks_a() {
        let name = Name::from_str("example.com.").unwrap();
        let mut msg = Message::new(1, MessageType::Response, OpCode::Query);
        msg.add_query(Query::query(name.clone(), RecordType::A));
        msg.add_answer(Record::from_rdata(
            name.clone(),
            300,
            RData::CNAME(rdata::CNAME(Name::from_str("alias.example.com.").unwrap())),
        ));
        msg.add_answer(Record::from_rdata(
            name,
            300,
            RData::A(rdata::A(Ipv4Addr::new(93, 184, 216, 34))),
        ));
        assert_eq!(
            first_a_record(&msg),
            Some(IpAddr::V4(Ipv4Addr::new(93, 184, 216, 34)))
        );
    }

    #[test]
    fn first_a_record_none_when_no_a_answer() {
        assert_eq!(first_a_record(&Message::query()), None);
    }

    #[test]
    fn dns_cache_round_trip() {
        let ip = IpAddr::V4(Ipv4Addr::new(1, 2, 3, 4));
        dns_cache_put("cache-test.example", ip);
        assert_eq!(dns_cache_get("cache-test.example"), Some(ip));
        assert_eq!(dns_cache_get("cache-miss.example"), None);
    }

    /// Stop any leftover proxy from a prior test (or a failed live bootstrap)
    /// and wait until status is `stopped`. Process-global atomics are shared
    /// across `nym::tests`, so one sticky `failed` must not poison the rest.
    fn ensure_nym_stopped() {
        stop_nym_proxy();
        let deadline = Instant::now() + Duration::from_secs(5);
        while Instant::now() < deadline {
            stop_nym_proxy();
            if nym_status() == "stopped" {
                return;
            }
            std::thread::sleep(Duration::from_millis(50));
        }
        panic!(
            "nym proxy did not reach stopped (status={})",
            nym_status()
        );
    }

    /// Always tear down the in-process proxy, even when the live test panics.
    struct NymProxyGuard;
    impl Drop for NymProxyGuard {
        fn drop(&mut self) {
            ensure_nym_stopped();
        }
    }

    #[test]
    fn status_reports_stopped_before_start() {
        ensure_nym_stopped();
        assert_eq!(nym_status(), "stopped");
    }

    #[test]
    fn stop_clears_sticky_failed_status() {
        ensure_nym_stopped();
        NYM_STATE.store(NYM_FAILED, Ordering::SeqCst);
        assert_eq!(nym_status(), "failed");
        stop_nym_proxy();
        assert_eq!(nym_status(), "stopped");
    }

    #[test]
    fn dns_query_bytes_is_a_recursive_a_query() {
        let bytes = dns_query_bytes("lilith0.dark.fi").unwrap();
        let msg = Message::from_vec(&bytes).unwrap();
        assert!(msg.metadata.recursion_desired);
        assert_eq!(msg.queries.len(), 1);
        assert_eq!(msg.queries[0].query_type(), RecordType::A);
    }

    #[test]
    fn resolvers_are_distinct_public_servers() {
        let mut seen = DNS_RESOLVERS.to_vec();
        seen.dedup();
        assert_eq!(seen.len(), DNS_RESOLVERS.len());
        assert!(DNS_RESOLVERS.iter().all(|r| r[0] != 127 && r[0] != 10));
    }

    #[test]
    fn wait_fails_fast_when_never_started() {
        ensure_nym_stopped();
        assert!(wait_until_running(Duration::from_millis(10)).is_err());
    }

    /// Live mainnet round trip: `cargo test -p darkfi-mobile-ffi nym_live -- --ignored`.
    #[test]
    #[ignore]
    fn nym_live_http_through_socks() {
        let _ = tracing_subscriber::fmt()
            .with_env_filter(tracing_subscriber::EnvFilter::new("warn,nym_smolmix=info"))
            .with_writer(std::io::stderr)
            .try_init();
        ensure_nym_stopped();
        let _guard = NymProxyGuard;
        let port = 19080;
        assert!(
            start_nym_proxy(port).expect("start_nym_proxy"),
            "expected a fresh nym bootstrap"
        );
        wait_until_running(Duration::from_secs(150)).unwrap_or_else(|e| {
            panic!("Nym mixnet bootstrap did not become ready: {e:?}");
        });
        let body = tokio::runtime::Runtime::new()
            .expect("tokio runtime")
            .block_on(async {
                let mut s = tokio_socks::tcp::Socks5Stream::connect(
                    ("127.0.0.1", port),
                    ("example.com", 80),
                )
                .await
                .unwrap_or_else(|e| panic!("SOCKS connect via Nym failed: {e}"));
                s.write_all(b"GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n")
                    .await
                    .unwrap_or_else(|e| panic!("HTTP write via Nym failed: {e}"));
                let mut buf = Vec::new();
                s.read_to_end(&mut buf)
                    .await
                    .unwrap_or_else(|e| panic!("HTTP read via Nym failed: {e}"));
                String::from_utf8_lossy(&buf).into_owned()
            });
        assert!(
            body.starts_with("HTTP/1.1 200") || body.starts_with("HTTP/1.0 200"),
            "expected HTTP 200 through Nym SOCKS, got: {body}"
        );
    }

    #[tokio::test]
    async fn socks_rejects_onion_without_dialling() {
        let listener = TcpListener::bind(("127.0.0.1", 0)).await.unwrap();
        let addr = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let (s, _) = listener.accept().await.unwrap();
            handle_socks_conn(s).await
        });
        let mut c = TcpStream::connect(addr).await.unwrap();
        c.write_all(&[0x05, 0x01, 0x00]).await.unwrap();
        let mut greet = [0u8; 2];
        c.read_exact(&mut greet).await.unwrap();
        assert_eq!(greet, [0x05, 0x00]);
        let host = b"abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefab.onion";
        let mut req = vec![0x05, 0x01, 0x00, 0x03, host.len() as u8];
        req.extend_from_slice(host);
        req.extend_from_slice(&9067u16.to_be_bytes());
        c.write_all(&req).await.unwrap();
        let mut reply = [0u8; 10];
        c.read_exact(&mut reply).await.unwrap();
        assert_eq!(reply[1], 0x04);
        assert!(server.await.unwrap().unwrap_err().contains("onion"));
    }
}
