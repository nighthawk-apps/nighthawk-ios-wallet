# Third-party sources

## `darkfi/`

Vendored [darkrenaissance/darkfi](https://github.com/darkrenaissance/darkfi) at the commit in
`docs/upstream/darkfi-revision.txt`.

Fetch or refresh:

```bash
./scripts/vendor-darkfi.sh
export DARKFI_SRC="$PWD/third_party/darkfi"
```

Used by:

- `rust/darkfi-mobile-ffi` — UniFFI wallet (`drk` / DarkFi path dependencies)
- `scripts/build-darkirc-ios.sh` — optional standalone DarkIRC binary

The full tree is **not** committed; run the vendor script after clone.
