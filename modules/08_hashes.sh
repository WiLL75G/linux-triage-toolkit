#!/usr/bin/env bash
#
# 08_hashes.sh - SHA-256 hashing for integrity verification
# MITRE ATT&CK: T1036 (Masquerading)
#
# Hashes commonly-abused system binaries (LOLBins) so a responder can
# diff them against known-good values and catch a trojanized replacement,
# plus hashes anything sitting in attacker staging directories
# (/tmp, /var/tmp, /dev/shm). Read-only; never alters the target files.
#
# Part of linux-triage-toolkit. Invoked by triage.sh, which passes the
# case directory as $1. Runs standalone too:
#   ./modules/08_hashes.sh /tmp/manual_case

set -euo pipefail

CASE_DIR="${1:?case directory required}"
OUT="${CASE_DIR}/08_hashes.txt"

section() {
    echo
    echo "=== $1 ==="
}

# Prefer sha256sum (GNU/Linux); fall back to shasum -a 256 (macOS/BSD).
# Never lets a single unreadable/permission-denied file kill the module.
hash_file() {
    local result
    if command -v sha256sum >/dev/null 2>&1; then
        result="$(sha256sum "$1" 2>/dev/null)" || { echo "unable to hash $1 (permission denied or unreadable)"; return 0; }
    elif command -v shasum >/dev/null 2>&1; then
        result="$(shasum -a 256 "$1" 2>/dev/null)" || { echo "unable to hash $1 (permission denied or unreadable)"; return 0; }
    else
        echo "no sha256 tool available for $1"
        return 0
    fi
    echo "$result"
}

{
    echo "############################################################"
    echo "# 08_hashes - SHA-256 integrity hashes"
    echo "# Collected: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Host:      $(hostname 2>/dev/null || echo unknown)"
    echo "############################################################"

    # ---------------------------------------------------------------
    # Common LOLBins / high-value system binaries.
    # A hash here that doesn't match the distro's known-good value is
    # a strong signal of tampering or a trojanized binary.
    # ---------------------------------------------------------------
    section "Common system binaries (LOLBins and core utilities)"
    for bin in /bin/bash /bin/sh /usr/bin/curl /usr/bin/wget /usr/bin/nc \
               /usr/bin/ncat /usr/bin/python3 /usr/bin/perl /usr/bin/ssh \
               /usr/sbin/sshd /usr/bin/sudo /usr/bin/su /bin/ls /bin/ps \
               /bin/netstat /usr/bin/crontab /usr/bin/systemctl; do
        if [ -e "$bin" ]; then
            hash_file "$bin"
        fi
    done

    # ---------------------------------------------------------------
    # Attacker staging directories. Anything here is worth a hash,
    # cross-reference against threat intel or VirusTotal.
    # ---------------------------------------------------------------
    section "Files in /tmp"
    if [ -d /tmp ]; then
        find /tmp -maxdepth 2 -type f 2>/dev/null | while read -r f; do
            hash_file "$f"
        done
    else
        echo "/tmp not present"
    fi

    section "Files in /var/tmp"
    if [ -d /var/tmp ]; then
        find /var/tmp -maxdepth 2 -type f 2>/dev/null | while read -r f; do
            hash_file "$f"
        done
    else
        echo "/var/tmp not present"
    fi

    section "Files in /dev/shm"
    if [ -d /dev/shm ]; then
        find /dev/shm -maxdepth 2 -type f 2>/dev/null | while read -r f; do
            hash_file "$f"
        done
    else
        echo "/dev/shm not present (not present on this system)"
    fi

    echo
    echo "=== 08_hashes complete ==="
} > "${OUT}"
