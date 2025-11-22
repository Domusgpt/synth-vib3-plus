#!/usr/bin/env bash
set -euo pipefail

# Lightweight Flutter bootstrapper for CI/dev containers.
# Downloads a pinned Flutter SDK to tools/flutter and exports
# PATH instructions without requiring sudo or snap.

CHANNEL=${CHANNEL:-stable}
VERSION=${VERSION:-3.24.0}
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
# The upstream archive unpacks to a top-level "flutter" directory; keep the
# same path here so PATH exports remain accurate across shells.
FLUTTER_DIR="${BASE_DIR}/flutter"
ARCHIVE="flutter_linux_${VERSION}-${CHANNEL}.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/${CHANNEL}/linux/${ARCHIVE}"

mkdir -p "${BASE_DIR}"

if [ -d "${FLUTTER_DIR}" ]; then
  echo "Flutter already present at ${FLUTTER_DIR}" >&2
  exit 0
fi

echo "Downloading Flutter ${VERSION} (${CHANNEL}) from ${URL}" >&2
curl -L "${URL}" -o "${BASE_DIR}/${ARCHIVE}"

echo "Extracting SDK..." >&2
tar -xf "${BASE_DIR}/${ARCHIVE}" -C "${BASE_DIR}"

# Avoid "dubious ownership" warnings when running flutter commands inside
# containers by trusting the extracted SDK path up-front. This is a no-op if
# the entry already exists.
if command -v git >/dev/null 2>&1; then
  git config --global --get-all safe.directory | grep -qx "${FLUTTER_DIR}" || \
    git config --global --add safe.directory "${FLUTTER_DIR}"
fi

cat <<'INSTRUCTIONS'

✅ Flutter SDK unpacked.
To use it in this shell, run:
  export PATH="${FLUTTER_DIR}/bin:$PATH"
  flutter doctor

For CI, add the PATH export to your job before running flutter commands.
INSTRUCTIONS
