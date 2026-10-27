#!/usr/bin/env bash
# Vendor the Nighthawk DarkFi pin into third_party/darkfi.
#
# git.dark.fi returns HTTP 504 and does not contain this SHA. Clone
# https://github.com/nighthawk24/darkfi (nighthawk-testnet) instead.
# Cargo then fetches kvdb-overlay, RandomX, and rust-url from GitLab,
# Codeberg, and GitHub. See docs/upstream/darkfi-revision.txt.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REV_FILE="${ROOT}/docs/upstream/darkfi-revision.txt"
DEST="${ROOT}/third_party/darkfi"

first_token="$(sed -n '1p' "${REV_FILE}" | awk '{print $1}')"
if [[ ! "${first_token}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: line 1 of ${REV_FILE} must start with a full 40-char lowercase hex SHA; got '${first_token}'" >&2
  exit 1
fi

if [[ ! -d "${DEST}/.git" ]]; then
  mkdir -p "$(dirname "${DEST}")"
  git clone --filter=blob:none https://github.com/nighthawk24/darkfi.git "${DEST}"
fi

(
  cd "${DEST}"
  git fetch --depth 1 origin "${first_token}"
  git checkout --detach "${first_token}"
)

actual="$(git -C "${DEST}" rev-parse HEAD)"
if [[ "${actual}" != "${first_token}" ]]; then
  echo "error: third_party/darkfi is ${actual}, expected ${first_token} (${REV_FILE})" >&2
  exit 1
fi

echo "Vendored darkfi @ ${first_token} → ${DEST}"
echo "Set DARKFI_SRC=${DEST} for scripts/build-darkirc-ios.sh"
