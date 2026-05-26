#!/usr/bin/env bash
#
# triage.sh - Linux Triage Toolkit
# Live response collector for Linux hosts during incident response.
#
# Author: Gokah Williams (@WiLL75G)
# License: MIT

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODULES_DIR="${SCRIPT_DIR}/modules"
OUTPUT_ROOT="${SCRIPT_DIR}/output"
HOSTNAME_SAFE="$(hostname | tr -c '[:alnum:]_-' '_')"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
CASE_DIR="${OUTPUT_ROOT}/${HOSTNAME_SAFE}_${TIMESTAMP}"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
log() {
    printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"
}

die() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

# ----------------------------------------------------------------------------
# Pre-flight
# ----------------------------------------------------------------------------
log "Linux Triage Toolkit starting"
log "Case directory: ${CASE_DIR}"

mkdir -p "${CASE_DIR}" || die "Could not create case directory"

# ----------------------------------------------------------------------------
# Run modules
# ----------------------------------------------------------------------------
shopt -s nullglob
for module in "${MODULES_DIR}"/*.sh; do
    module_name="$(basename "${module}" .sh)"
    log "Running module: ${module_name}"

    if bash "${module}" "${CASE_DIR}"; then
        log "  -> ${module_name} OK"
    else
        log "  -> ${module_name} FAILED (continuing)"
    fi
done
shopt -u nullglob

# ----------------------------------------------------------------------------
# Bundle + integrity hash
# ----------------------------------------------------------------------------
BUNDLE="${CASE_DIR}.tar.gz"
log "Bundling artifacts -> ${BUNDLE}"
tar -czf "${BUNDLE}" -C "${OUTPUT_ROOT}" "$(basename "${CASE_DIR}")"

log "Generating SHA256 of bundle (chain of custody)"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${BUNDLE}" > "${BUNDLE}.sha256"
else
    # macOS fallback (uses shasum)
    shasum -a 256 "${BUNDLE}" > "${BUNDLE}.sha256"
fi

log "Done. Bundle: ${BUNDLE}"
log "Hash file:    ${BUNDLE}.sha256"
