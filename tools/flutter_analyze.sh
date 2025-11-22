#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="${ROOT_DIR}/tools/flutter"
LOG_DIR="${ROOT_DIR}/tools/logs"
LOG_FILE="${LOG_DIR}/flutter_analyze.log"

if [ ! -d "${FLUTTER_DIR}" ]; then
  echo "Flutter SDK not found at ${FLUTTER_DIR}. Run tools/flutter_bootstrap.sh first." >&2
  exit 1
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

# Prevent 'dubious ownership' warnings from the vendored SDK.
if command -v git >/dev/null 2>&1; then
  git config --global --get-all safe.directory | grep -qx "${FLUTTER_DIR}" || \
    git config --global --add safe.directory "${FLUTTER_DIR}"
fi

mkdir -p "${LOG_DIR}"

echo "Writing analyzer output to ${LOG_FILE}" >&2
# Keep the exit code from flutter analyze even when piping through tee.
set +e
flutter analyze "$@" | tee "${LOG_FILE}"
STATUS=${PIPESTATUS[0]}
set -e
exit ${STATUS}
