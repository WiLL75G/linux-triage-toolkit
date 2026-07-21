#!/usr/bin/env bash
#
# 07_logs.sh - Log and history collection for Linux triage
#
# Collects the authentication, system, and shell-history evidence a
# responder reaches for first: who logged in, what the system recorded,
# what the kernel and services said, and what commands were run.
#
# Part of linux-triage-toolkit. Invoked by triage.sh, which sets OUT to
# this module's output file. Runs standalone too:  ./modules/07_logs.sh
#
# Design rules (shared across all modules):
#   - Everything wrapped in a single { ... } > "${OUT}" redirect
#   - Never crash on a missing file or missing privilege; say so instead
#   - Prefer read-only collection; copy nothing, alter nothing
#   - Root reads more (auth.log, lastb); the tool degrades gracefully

set -o pipefail

# When run standalone, OUT is not set by the orchestrator. Fall back to
# stdout so the module is still useful on its own.
OUT="${OUT:-/dev/stdout}"

# Small helper: print a section header, then run whatever is passed.
section() {
    echo
    echo "=== $1 ==="
}

# Small helper: report a file we cannot read rather than failing silently.
need_readable() {
    # $1 = path, $2 = human label
    if [ ! -e "$1" ]; then
        echo "[$2] not present on this host ($1)"
        return 1
    fi
    if [ ! -r "$1" ]; then
        echo "[$2] present but not readable with current privileges ($1) - re-run as root for this artifact"
        return 1
    fi
    return 0
}

{
    echo "############################################################"
    echo "# 07_logs - authentication, system, and shell history"
    echo "# Collected: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Host:      $(hostname 2>/dev/null || echo unknown)"
    echo "# Collector: $(id -un 2>/dev/null || echo unknown) (uid $(id -u 2>/dev/null || echo '?'))"
    echo "############################################################"

    # ---------------------------------------------------------------
    # Authentication log
    # Debian/Ubuntu: /var/log/auth.log   RHEL/CentOS: /var/log/secure
    # This is the first place a brute force or privilege abuse shows up.
    # ---------------------------------------------------------------
    section "Authentication log (last 200 lines)"
    AUTH_LOG=""
    if [ -e /var/log/auth.log ]; then
        AUTH_LOG="/var/log/auth.log"
    elif [ -e /var/log/secure ]; then
        AUTH_LOG="/var/log/secure"
    fi

    if [ -z "$AUTH_LOG" ]; then
        echo "No auth.log or secure found; system may log auth to journald only (see journalctl section below)"
    elif need_readable "$AUTH_LOG" "auth log"; then
        echo "Source: $AUTH_LOG"
        tail -n 200 "$AUTH_LOG" 2>/dev/null
    fi

    section "Failed password attempts (from auth log)"
    if [ -n "$AUTH_LOG" ] && [ -r "$AUTH_LOG" ]; then
        # Count failures per source IP; a spike from one IP is a brute force.
        if grep -qi "failed password" "$AUTH_LOG" 2>/dev/null; then
            grep -i "failed password" "$AUTH_LOG" 2>/dev/null \
                | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" \
                | awk '{print $2}' \
                | sort | uniq -c | sort -rn \
                | awk '{printf "  %6s failures from %s\n", $1, $2}'
        else
            echo "No failed password entries in $AUTH_LOG"
        fi
    else
        echo "Auth log unavailable; skipping failed-password summary"
    fi

    section "Accepted logins (from auth log)"
    if [ -n "$AUTH_LOG" ] && [ -r "$AUTH_LOG" ]; then
        if grep -qi "accepted" "$AUTH_LOG" 2>/dev/null; then
            grep -i "accepted" "$AUTH_LOG" 2>/dev/null | tail -n 40
        else
            echo "No accepted-login entries in $AUTH_LOG"
        fi
    else
        echo "Auth log unavailable; skipping accepted-login summary"
    fi

    section "sudo invocations (from auth log)"
    if [ -n "$AUTH_LOG" ] && [ -r "$AUTH_LOG" ]; then
        if grep -qi "sudo:" "$AUTH_LOG" 2>/dev/null; then
            grep -i "sudo:" "$AUTH_LOG" 2>/dev/null | tail -n 40
        else
            echo "No sudo entries in $AUTH_LOG"
        fi
    else
        echo "Auth log unavailable; skipping sudo summary"
    fi

    # ---------------------------------------------------------------
    # Login records: successful (last) and failed (lastb)
    # lastb needs root. This is where an attacker's session shows up.
    # ---------------------------------------------------------------
    section "Recent successful logins (last -20)"
    if command -v last >/dev/null 2>&1; then
        last -a -n 20 2>/dev/null || echo "last returned no data"
    else
        echo "last command not available"
    fi

    section "Recent failed logins (lastb -20)"
    if command -v lastb >/dev/null 2>&1; then
        # lastb reads /var/log/btmp and typically requires root.
        LASTB_OUT="$(lastb -a -n 20 2>/dev/null)"
        if [ -n "$LASTB_OUT" ]; then
            echo "$LASTB_OUT"
        else
            echo "lastb returned no data (btmp empty, or root required for /var/log/btmp)"
        fi
    else
        echo "lastb command not available"
    fi

    # ---------------------------------------------------------------
    # System log
    # Debian/Ubuntu: /var/log/syslog     RHEL/CentOS: /var/log/messages
    # ---------------------------------------------------------------
    section "System log (last 100 lines)"
    SYS_LOG=""
    if [ -e /var/log/syslog ]; then
        SYS_LOG="/var/log/syslog"
    elif [ -e /var/log/messages ]; then
        SYS_LOG="/var/log/messages"
    fi

    if [ -z "$SYS_LOG" ]; then
        echo "No syslog or messages found; system likely logs to journald only"
    elif need_readable "$SYS_LOG" "system log"; then
        echo "Source: $SYS_LOG"
        tail -n 100 "$SYS_LOG" 2>/dev/null
    fi

    # ---------------------------------------------------------------
    # journald: the modern log store. Covers hosts with no text logs.
    # ---------------------------------------------------------------
    section "journalctl - recent entries (last 100)"
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -n 100 --no-pager 2>/dev/null \
            || echo "journalctl present but returned no data (may require root or systemd-journald not running)"
    else
        echo "journalctl not available; system is not using systemd-journald"
    fi

    section "journalctl - priority err and above (last 50)"
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -p err -n 50 --no-pager 2>/dev/null \
            || echo "No high-priority journal entries, or root required"
    else
        echo "journalctl not available"
    fi

    section "journalctl - this boot, sshd unit (last 50)"
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -u ssh -u sshd -b -n 50 --no-pager 2>/dev/null \
            || echo "No sshd journal entries this boot, or root required"
    else
        echo "journalctl not available"
    fi

    # ---------------------------------------------------------------
    # Shell history: forensic gold. What did the account actually run?
    # We enumerate history files for every real user, not just current.
    # ---------------------------------------------------------------
    section "Shell history files (per user)"
    # Build a list of home directories from /etc/passwd (uid >= 1000 plus root).
    if [ -r /etc/passwd ]; then
        awk -F: '($3 == 0 || $3 >= 1000) && $6 != "" {print $1":"$6}' /etc/passwd 2>/dev/null \
        | while IFS=":" read -r username homedir; do
            for hist in ".bash_history" ".zsh_history" ".sh_history" ".ash_history"; do
                hpath="${homedir}/${hist}"
                if [ -e "$hpath" ]; then
                    echo
                    echo "--- ${username}: ${hpath} ---"
                    if [ -r "$hpath" ]; then
                        # Timestamp metadata first, then the tail of the history.
                        stat -c '  modified: %y  size: %s bytes' "$hpath" 2>/dev/null \
                            || stat -f '  modified: %Sm  size: %z bytes' "$hpath" 2>/dev/null
                        echo "  last 50 commands:"
                        tail -n 50 "$hpath" 2>/dev/null | sed 's/^/    /'
                    else
                        echo "  present but not readable with current privileges - re-run as root"
                    fi
                fi
            done
        done
    else
        echo "/etc/passwd not readable; cannot enumerate per-user history"
    fi

    # ---------------------------------------------------------------
    # Log integrity signal: has anything been truncated or tampered?
    # A zero-byte auth.log on a live host is a red flag worth surfacing.
    # ---------------------------------------------------------------
    section "Log integrity signals"
    for f in "$AUTH_LOG" "$SYS_LOG" /var/log/btmp /var/log/wtmp; do
        [ -z "$f" ] && continue
        if [ -e "$f" ]; then
            sz=$(stat -c '%s' "$f" 2>/dev/null || stat -f '%z' "$f" 2>/dev/null)
            if [ "$sz" = "0" ]; then
                echo "  WARNING: $f exists but is zero bytes (possible clearing/tampering)"
            else
                echo "  OK: $f is ${sz} bytes"
            fi
        fi
    done

    echo
    echo "=== 07_logs complete ==="
} > "${OUT}"
