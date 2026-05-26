#!/usr/bin/env bash
#
# 01_system_info.sh - Collect basic system identification
# MITRE ATT&CK: T1082 (System Information Discovery)
#
# Receives the case directory as $1.

set -euo pipefail

CASE_DIR="${1:?case directory required}"
OUT="${CASE_DIR}/01_system_info.txt"

{
    echo "=== System Information ==="
    echo "Collected (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo

    echo "--- Hostname ---"
    hostname
    echo

    echo "--- Kernel (uname -a) ---"
    uname -a
    echo

    echo "--- OS release ---"
    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release
    else
        echo "/etc/os-release not present"
    fi
    echo

    echo "--- Uptime ---"
    uptime
    echo

    echo "--- Date / Timezone ---"
    date
    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl
    fi
} > "${OUT}"
