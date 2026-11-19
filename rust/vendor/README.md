# Vendored crates

## sysinfo-0.38.4

Tracked copy of crates.io `sysinfo 0.38.4` with iOS build fixes applied:

- `src/unix/apple/process.rs`: `open_files()` returns `None` on iOS / apple-sandbox (no `proc_pidinfo` listfds).
- `src/unix/apple/network.rs`: define `RTM_IFINFO2` locally (missing from iOS libc bindings).

Referenced from `rust/Cargo.toml` via `[patch.crates-io]`. Do not edit the crates.io cache under `.cargo-home`.
