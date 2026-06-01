#!/usr/bin/env bash
#
# 02_users.sh - Collect user and session information
# MITRE ATT&CK: T1087 (Account Discovery), T1078 (Valid Accounts)
#
# Receives the case directory as $1.

set -euo pipefail

CASE_DIR="${1:?case directory required}"
OUT="${CASE_DIR}/02_users.txt"

{
    echo "=== Users & Sessions ==="
    echo "Collected (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo

    echo "--- Currently logged in (who) ---"
    who 2>/dev/null || echo "who unavailable"
    echo

    echo "--- Active sessions (w) ---"
    w 2>/dev/null || echo "w unavailable"
    echo

    echo "--- Last 20 logins (last) ---"
    last -n 20 2>/dev/null || echo "last unavailable"
    echo

    echo "--- Failed login attempts (lastb) ---"
    if command -v lastb >/dev/null 2>&1; then
        lastb -n 20 2>/dev/null || echo "lastb requires root"
    else
        echo "lastb not available on this system"
    fi
    echo

    echo "--- /etc/passwd (all accounts) ---"
    cat /etc/passwd 2>/dev/null || echo "Cannot read /etc/passwd"
    echo

    echo "--- Accounts with UID 0 (root-equivalent) ---"
    awk -F: '$3 == 0 {print}' /etc/passwd 2>/dev/null || echo "N/A"
    echo

    echo "--- Sudoers (if readable) ---"
    if [[ -r /etc/sudoers ]]; then
        grep -vE '^\s*(#|$)' /etc/sudoers
    else
        echo "/etc/sudoers not readable (requires root)"
    fi
} > "${OUT}"
