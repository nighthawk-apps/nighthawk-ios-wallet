# Third-party sources

## `darkfi/`

Vendored [nighthawk24/darkfi](https://github.com/nighthawk24/darkfi) at the commit in
`docs/upstream/darkfi-revision.txt` (`0e87090e9`, `nighthawk-testnet`).

`git.dark.fi` returns HTTP 504 and does not have that pin. Inside the tree,
`kvdb-overlay` comes from GitLab, RandomX from Codeberg, and `rust-url` from GitHub.

Fetch or refresh:

```bash
./scripts/vendor-darkfi.sh
export DARKFI_SRC="$PWD/third_party/darkfi"
```

Used by:

- `rust/darkfi-mobile-ffi` — UniFFI wallet (`drk` / DarkFi path dependencies)
- `scripts/build-darkirc-ios.sh` — optional standalone DarkIRC binary

The full tree is **not** committed; run the vendor script after clone.
