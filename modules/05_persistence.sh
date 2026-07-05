#!/usr/bin/env bash
#
# 05_persistence.sh - Collect persistence mechanisms
# MITRE ATT&CK: T1053 (Scheduled Task), T1543 (System Process),
#               T1547 (Autostart), T1098 (Account Manipulation),
#               T1546 (Event Triggered Execution), T1574 (Hijack Execution Flow)
#
# Answers "how would the attacker come back if we rebooted?"
# Receives the case directory as $1.

set -euo pipefail

CASE_DIR="${1:?case directory required}"
OUT="${CASE_DIR}/05_persistence.txt"

{
    echo "=== Persistence Mechanisms ==="
    echo "Collected (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo

    echo "--- System-wide cron (/etc/crontab) ---"
    if [[ -r /etc/crontab ]]; then
        cat /etc/crontab
    else
        echo "/etc/crontab not present or not readable"
    fi
    echo

    echo "--- /etc/cron.d/ drop-in files ---"
    if [[ -d /etc/cron.d ]]; then
        ls -la /etc/cron.d/ 2>/dev/null
        for f in /etc/cron.d/*; do
            [[ -f "$f" ]] || continue
            echo ">>> $f"
            cat "$f" 2>/dev/null
        done
    else
        echo "/etc/cron.d not present"
    fi
    echo

    echo "--- /etc/cron.{hourly,daily,weekly,monthly}/ ---"
    for d in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
        echo ">>> $d"
        ls -la "$d" 2>/dev/null || echo "N/A"
    done
    echo

    echo "--- User crontabs (/var/spool/cron) ---"
    if [[ -d /var/spool/cron ]]; then
        ls -laR /var/spool/cron/ 2>/dev/null
        for u in /var/spool/cron/crontabs/* /var/spool/cron/*; do
            [[ -f "$u" ]] || continue
            echo ">>> $u"
            cat "$u" 2>/dev/null
        done
    else
        echo "/var/spool/cron not present"
    fi
    echo

    echo "--- Enabled systemd services ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-unit-files --type=service --state=enabled 2>/dev/null || true
    else
        echo "systemctl not available"
    fi
    echo

    echo "--- Systemd timers ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-timers --all 2>/dev/null || true
    else
        echo "systemctl not available"
    fi
    echo

    echo "--- rc.local and init.d ---"
    if [[ -f /etc/rc.local ]]; then
        echo ">>> /etc/rc.local"
        cat /etc/rc.local
    else
        echo "/etc/rc.local not present"
    fi
    echo ">>> /etc/init.d (top 30 entries)"
    ls -la /etc/init.d/ 2>/dev/null | head -n 30 || echo "N/A"
    echo

    echo "--- SSH authorized_keys across all users ---"
    for home in /root /home/*; do
        ak="${home}/.ssh/authorized_keys"
        if [[ -f "${ak}" ]]; then
            echo ">>> ${ak}"
            cat "${ak}" 2>/dev/null
        fi
    done
    echo

    echo "--- Shell rc files (size + mtime for hijack detection) ---"
    for home in /root /home/*; do
        for rc in .bashrc .bash_profile .profile .zshrc .zprofile; do
            f="${home}/${rc}"
            if [[ -f "${f}" ]]; then
                size=$(wc -c < "${f}" 2>/dev/null || echo "?")
                mtime=$(stat -c %y "${f}" 2>/dev/null || stat -f "%Sm" "${f}" 2>/dev/null || echo "?")
                echo "${f} | size: ${size} bytes | modified: ${mtime}"
            fi
        done
    done
    echo

    echo "--- /etc/ld.so.preload (dynamic linker hijack indicator) ---"
    if [[ -f /etc/ld.so.preload ]]; then
        echo "!! /etc/ld.so.preload EXISTS -- inspect immediately"
        cat /etc/ld.so.preload
    else
        echo "/etc/ld.so.preload not present (expected on clean systems)"
    fi
    echo

    echo "--- /etc/profile.d/ scripts ---"
    if [[ -d /etc/profile.d ]]; then
        ls -la /etc/profile.d/ 2>/dev/null
    else
        echo "/etc/profile.d not present"
    fi
} > "${OUT}"
