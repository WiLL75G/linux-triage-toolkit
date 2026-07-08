#!/usr/bin/env bash
#
# 06_files.sh - Suspicious file artifacts
# MITRE ATT&CK: T1083 (File and Directory Discovery),
#               T1222 (File and Directory Permissions Modification)
#
# Surfaces recently-modified files, SUID/SGID binaries, world-writable files,
# and contents of common attacker staging directories (/tmp, /var/tmp, /dev/shm).
# Receives the case directory as $1.

set -euo pipefail

CASE_DIR="${1:?case directory required}"
OUT="${CASE_DIR}/06_files.txt"

{
    echo "=== File Artifacts ==="
    echo "Collected (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo

    echo "--- Files modified in last 24h (top 200, excluding noisy dirs) ---"
    find / -xdev -type f -mtime -1 \
        -not -path "/proc/*" \
        -not -path "/sys/*" \
        -not -path "/run/*" \
        -not -path "/var/log/*" \
        -not -path "*/.git/*" \
        2>/dev/null | head -n 200 || true
    echo

    echo "--- SUID binaries (runs as file owner, common privesc vector) ---"
    find / -xdev -type f -perm -4000 2>/dev/null | head -n 200 || true
    echo

    echo "--- SGID binaries (runs as file group) ---"
    find / -xdev -type f -perm -2000 2>/dev/null | head -n 200 || true
    echo

    echo "--- World-writable files (outside /tmp, /proc, /sys, top 100) ---"
    find / -xdev -type f -perm -0002 \
        -not -path "/tmp/*" \
        -not -path "/proc/*" \
        -not -path "/sys/*" \
        -not -path "/private/tmp/*" \
        2>/dev/null | head -n 100 || true
    echo

    echo "--- Contents of /tmp ---"
    ls -la /tmp 2>/dev/null || echo "N/A"
    echo

    echo "--- Contents of /var/tmp ---"
    ls -la /var/tmp 2>/dev/null || echo "N/A"
    echo

    echo "--- Contents of /dev/shm (RAM-backed, attacker favorite) ---"
    ls -la /dev/shm 2>/dev/null || echo "N/A (not present on this system)"
} > "${OUT}"
