#!/usr/bin/env bash
# Vendor nighthawk24/darkfi at docs/upstream/darkfi-revision.txt into third_party/darkfi.
# Do not clone darkrenaissance/darkfi — we do not change upstream.
#
# Pin format: line 1 must start with a full 40-char lowercase hex SHA.
# Further tokens / later lines may be comments.
#
# After checkout, compiles event_graph *.zk.bin (required by the darkfi crate).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REV_FILE="${ROOT}/docs/upstream/darkfi-revision.txt"
DEST="${ROOT}/third_party/darkfi"

first_token="$(sed -n '1p' "${REV_FILE}" | awk '{print $1}')"
if [[ ! "${first_token}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: line 1 of ${REV_FILE} must start with a full 40-char lowercase hex SHA; got '${first_token}'" >&2
  exit 1
fi

# Symlink to a shared darkrenaissance/darkfi master checkout is a footgun:
# git checkout below would move that repo off master.
if [[ -L "$DEST" ]]; then
  target="$(readlink "$DEST" || true)"
  echo "third_party/darkfi is a symlink → ${target}"
  echo "Safe: ../new-nighthawk-android-wallet/third_party/darkfi or sibling darkfi-nighthawk-testnet"
  echo "at pin ${first_token} (nighthawk24 nighthawk-testnet). Not GitHub darkfi master."
  current="$(git -C "$DEST" rev-parse HEAD 2>/dev/null || true)"
  if [[ "$current" == "$first_token" ]]; then
    echo "symlink already at pin — skip checkout"
    DARKFI_SRC="$DEST" "$ROOT/scripts/compile-darkfi-zkas-proofs.sh"
    echo "Vendored darkfi @ ${first_token} → ${DEST} (symlink, unchanged)"
    echo "Set DARKFI_SRC=${DEST} for scripts/build-darkirc-ios.sh"
    exit 0
  fi
  if [[ "${FORCE_VENDOR_SYMLINK:-}" != "1" ]]; then
    echo "error: refusing to git checkout through a symlink (would move ${target})." >&2
    echo "  ln -sfn ../new-nighthawk-android-wallet/third_party/darkfi third_party/darkfi" >&2
    echo "  # or FORCE_VENDOR_SYMLINK=1 $0" >&2
    exit 1
  fi
fi

if [[ ! -d "${DEST}/.git" ]]; then
  git clone --filter=blob:none https://github.com/nighthawk24/darkfi.git "${DEST}"
fi

(
  cd "${DEST}"
  # Existing checkouts may still point at darkrenaissance; retarget to nighthawk24.
  git remote set-url origin https://github.com/nighthawk24/darkfi.git
  # Drop any local SQLCipher/drk overlays so the tree matches the pin exactly.
  # Avoid `git clean -x` so a pre-built target/ and zk.bin caches can be reused when present.
  git reset --hard HEAD >/dev/null
  git clean -fd >/dev/null
  git fetch --depth 1 origin "${first_token}"
  git checkout --detach "${first_token}"
)

DARKFI_SRC="$DEST" "$ROOT/scripts/compile-darkfi-zkas-proofs.sh"

echo "Vendored darkfi @ ${first_token} → ${DEST}"
echo "Set DARKFI_SRC=${DEST} for scripts/build-darkirc-ios.sh"
