#!/usr/bin/env bash
set -euo pipefail

# Installs a pinned Flutter SDK for local development and CI usage.
# Defaults to /opt/flutter and Flutter 3.24.0 (Linux x64).

FLUTTER_VERSION="3.24.0-stable"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}.tar.xz"
DOWNLOAD_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${ARCHIVE}"
INSTALL_DIR="${FLUTTER_HOME:-/opt/flutter}"
CACHE_DIR="${FLUTTER_CACHE:-/tmp/flutter-cache}" # cache downloads between runs

mkdir -p "${CACHE_DIR}" "${INSTALL_DIR%/*}"
ARCHIVE_PATH="${CACHE_DIR}/${ARCHIVE}"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
  echo "Downloading Flutter ${FLUTTER_VERSION}..."
  curl -fLo "${ARCHIVE_PATH}" "${DOWNLOAD_URL}"
else
  echo "Using cached archive at ${ARCHIVE_PATH}"
fi

# Clean any existing install before expanding the archive to avoid corrupt states.
if [[ -d "${INSTALL_DIR}" ]]; then
  echo "Removing existing Flutter install at ${INSTALL_DIR}"
  rm -rf "${INSTALL_DIR}"
fi

mkdir -p "${INSTALL_DIR}"

echo "Expanding Flutter SDK to ${INSTALL_DIR}..."
tar xf "${ARCHIVE_PATH}" -C "${INSTALL_DIR%/*}"

# Archive contains a top-level flutter/ directory; move into place if needed.
if [[ -d "${INSTALL_DIR%/*}/flutter" && "${INSTALL_DIR}" != "${INSTALL_DIR%/*}/flutter" ]]; then
  mv "${INSTALL_DIR%/*}/flutter" "${INSTALL_DIR}"
fi

# Allow Flutter tooling to read its own git metadata when run as root (common in CI).
git config --global --add safe.directory "${INSTALL_DIR}" || true

export PATH="${INSTALL_DIR}/bin:${PATH}"

flutter --version
flutter doctor -v
