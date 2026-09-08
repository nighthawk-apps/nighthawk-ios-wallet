# Third-party sources

## `darkfi/`

Vendored [nighthawk24/darkfi](https://github.com/nighthawk24/darkfi) `nighthawk-testnet`
at the commit in `docs/upstream/darkfi-revision.txt` (`327fa9f13…`).
**Do not** point this directory at `darkrenaissance/darkfi` master (wrong Arti / no overlay).
A symlink to `../new-nighthawk-android-wallet/third_party/darkfi` or sibling
`darkfi-nighthawk-testnet` at that pin is the intended reuse path.

Fetch or refresh:

```bash
./scripts/vendor-darkfi.sh
export DARKFI_SRC="$PWD/third_party/darkfi"
```

The vendor script **hard-resets** the tree to the pin (drops local overlays).

Used by:

- `rust/darkfi-mobile-ffi` — UniFFI wallet (`drk` / DarkFi path dependencies, turso/aegis256)
- `scripts/build-darkirc-ios.sh` — optional standalone DarkIRC binary

The full tree is **not** committed; run the vendor script after clone.
