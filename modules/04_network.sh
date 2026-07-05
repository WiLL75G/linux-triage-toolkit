#!/usr/bin/env bash
#
# 04_network.sh - Collect network state
# MITRE ATT&CK: T1049 (System Network Connections Discovery), T1016 (System Network Configuration Discovery)
#
# Answers "where is this host talking to right now?"
# Receives the case directory as $1.

set -euo pipefail

CASE_DIR="${1:?case directory required}"
OUT="${CASE_DIR}/04_network.txt"

{
    echo "=== Network State ==="
    echo "Collected (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo

    echo "--- Interfaces ---"
    if command -v ip >/dev/null 2>&1; then
        ip -br addr 2>/dev/null || ip addr
    else
        ifconfig 2>/dev/null || echo "ifconfig unavailable"
    fi
    echo

    echo "--- Routing table ---"
    if command -v ip >/dev/null 2>&1; then
        ip route 2>/dev/null
    else
        netstat -rn 2>/dev/null || echo "netstat unavailable"
    fi
    echo

    echo "--- Listening sockets (ss -tulnp) ---"
    if command -v ss >/dev/null 2>&1; then
        ss -tulnp 2>/dev/null || ss -tuln
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tulnp 2>/dev/null || netstat -tuln
    else
        echo "Neither ss nor netstat available"
    fi
    echo

    echo "--- Established connections ---"
    if command -v ss >/dev/null 2>&1; then
        ss -tnp state established 2>/dev/null || ss -tn state established 2>/dev/null || echo "ss established query failed"
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tn 2>/dev/null | grep ESTABLISHED || echo "no established connections"
    else
        echo "Neither ss nor netstat available"
    fi
    echo

    echo "--- ARP table ---"
    if command -v ip >/dev/null 2>&1; then
        ip neigh 2>/dev/null || echo "ip neigh unavailable"
    else
        arp -a 2>/dev/null || echo "arp unavailable"
    fi
    echo

    echo "--- DNS resolvers (/etc/resolv.conf) ---"
    if [[ -r /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
    else
        echo "resolv.conf unreadable or missing"
    fi
    echo

    echo "--- iptables rules ---"
    if command -v iptables >/dev/null 2>&1; then
        iptables -L -n -v 2>/dev/null || echo "iptables requires root"
    else
        echo "iptables not installed"
    fi
    echo

    echo "--- nftables ruleset ---"
    if command -v nft >/dev/null 2>&1; then
        nft list ruleset 2>/dev/null || echo "nft requires root"
    else
        echo "nft not installed"
    fi
    echo

    echo "--- Hostname resolution check (/etc/hosts) ---"
    if [[ -r /etc/hosts ]]; then
        grep -vE '^\s*(#|$)' /etc/hosts || echo "no non-comment entries"
    else
        echo "/etc/hosts unreadable"
    fi
} > "${OUT}"
