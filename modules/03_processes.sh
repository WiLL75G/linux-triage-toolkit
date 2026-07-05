#!/usr/bin/env bash
#
# 03_processes.sh - Collect running process information
# MITRE ATT&CK: T1057 (Process Discovery)
#
# Includes deleted-binary detection to surface fileless / evasive malware.
# Receives the case directory as $1.

set -euo pipefail

CASE_DIR="${1:?case directory required}"
OUT="${CASE_DIR}/03_processes.txt"

{
    echo "=== Running Processes ==="
    echo "Collected (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo

    echo "--- Full process list (ps -eF) ---"
    ps -eF 2>/dev/null || ps aux
    echo

    echo "--- Process tree ---"
    if command -v pstree >/dev/null 2>&1; then
        pstree -ap 2>/dev/null || pstree
    else
        echo "pstree not installed"
    fi
    echo

    echo "--- Processes with deleted binaries (T1055 evasion indicator) ---"
    if [[ -d /proc ]]; then
        found=0
        for pid_dir in /proc/[0-9]*; do
            exe_link="${pid_dir}/exe"
            if [[ -L "${exe_link}" ]]; then
                target=$(readlink "${exe_link}" 2>/dev/null || true)
                if [[ "${target}" == *"(deleted)"* ]]; then
                    pid="$(basename "${pid_dir}")"
                    cmdline=$(tr '\0' ' ' < "${pid_dir}/cmdline" 2>/dev/null || echo "N/A")
                    echo "PID ${pid} -> ${target}"
                    echo "  cmdline: ${cmdline}"
                    found=1
                fi
            fi
        done
        if [[ ${found} -eq 0 ]]; then
            echo "No processes with deleted binaries detected."
        fi
    else
        echo "/proc not available (not Linux -- expected on macOS)"
    fi
    echo

    echo "--- Top 10 CPU consumers ---"
    { ps -eo pid,user,%cpu,%mem,command --sort=-%cpu 2>/dev/null | head -n 11; } \
        || { ps aux | sort -k3 -nr | head -n 10; } \
        || true
    echo

    echo "--- Top 10 memory consumers ---"
    { ps -eo pid,user,%cpu,%mem,command --sort=-%mem 2>/dev/null | head -n 11; } \
        || { ps aux | sort -k4 -nr | head -n 10; } \
        || true
} > "${OUT}"
