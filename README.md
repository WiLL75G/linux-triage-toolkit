<div align="center">
  <img src="banner.svg" alt="Banner" width="100%" />
</div>

# linux-triage-toolkit

**A modular Bash-based live response collector for Linux hosts during incident response.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/shell-Bash%204.4%2B-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Platform: Linux](https://img.shields.io/badge/platform-Linux-blue.svg)]()
[![Status: In Development](https://img.shields.io/badge/status-in%20development-orange.svg)]()
[![MITRE ATT&CK](https://img.shields.io/badge/MITRE-ATT%26CK%20mapped-red.svg)](https://attack.mitre.org/)

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Why This Project Exists](#-why-this-project-exists)
- [Project Status](#-project-status)
- [Features](#-features)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Usage](#-usage)
- [Module Catalog](#-module-catalog)
- [MITRE ATT&CK Coverage](#-mitre-attck-coverage)
- [Sample Output](#-sample-output)
- [Build Roadmap](#-build-roadmap)
- [Repository Structure](#-repository-structure)
- [Limitations & Future Work](#-limitations--future-work)
- [Author](#-author)
- [License](#-license)

---

## 🔍 Overview

`linux-triage-toolkit` is a defensive security tool designed for **Tier 1 SOC analysts and incident responders** who need to rapidly snapshot the state of a potentially compromised Linux host before evidence is lost.

When a host is suspected of compromise, **volatile data disappears fast** running processes, network connections, attacker shells, and in-memory artifacts can all vanish on reboot or remediation. This toolkit captures that volatile state, plus key persistence and forensic artifacts, into a portable evidence bundle with an integrity hash for chain of custody.

---

## 🎯 Why This Project Exists

In real-world incident response engagements, three problems consistently slow analysts down:

1. **Ad-hoc collection is inconsistent.** Different analysts pull different artifacts on different hosts, making cross-incident comparison difficult.
2. **Commercial tools have a learning curve.** Velociraptor, UAC, and similar tools are powerful but introduce dependencies, GUIs, and configuration overhead.
3. **Understanding *what* to collect is a real skill.** Knowing the volatility hierarchy, the difference between persistence techniques, and the value of process artifacts versus log artifacts is **a Tier 1 → Tier 2 skill** that this project documents.

`linux-triage-toolkit` solves all three: a **consistent, reproducible** collection workflow built on **standard Bash and POSIX tools** with **inline MITRE ATT&CK mapping** so every artifact has a documented investigative purpose.

---

## 📌 Project Status

> 🚧 **Active development** Day 1 of a 7-day public build series.

Current capability: orchestrator + system information module operational.
See the [Build Roadmap](#-build-roadmap) for the daily release schedule.

---

## ✨ Features

### Current (Day 1)

- ✅ **Modular architecture** each collection module is a self-contained Bash script under `modules/`
- ✅ **UTC timestamping** all timestamps are ISO-8601 UTC for cross-timezone IR correlation
- ✅ **Defensive Bash** every script uses `set -euo pipefail` to fail loud, not silent
- ✅ **Chain of custody** every triage bundle is tarballed and SHA-256 hashed
- ✅ **Per-module fault tolerance** if one module fails, the others still run
- ✅ **System identification** hostname, kernel, OS release, uptime, timezone (MITRE T1082)

### Planned (Days 2 – 7)

- 🔜 User & session collection (T1087)
- 🔜 Process discovery, including deleted-binary detection via `/proc` (T1057)
- 🔜 Network state listeners, established connections, ARP, firewall (T1049, T1016)
- 🔜 Persistence hunting cron, systemd, SSH keys, shell rc files (T1543, T1053)
- 🔜 File artifacts recent modifications, SUID/SGID, world-writable (T1083)
- 🔜 Log collection `auth.log`, syslog, journal, bash history (T1070)
- 🔜 SHA-256 hashing of suspicious binaries for IOC sharing

---

## 🏛 Architecture

```
                   ┌────────────────────┐
                   │     triage.sh      │   Orchestrator
                   │  (entry point)     │   • Creates case dir
                   └─────────┬──────────┘   • Loads each module
                             │              • Bundles + hashes
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
       ┌────────────┐ ┌────────────┐ ┌────────────┐
       │ 01_system  │ │ 02_users   │ │ 0N_module  │
       │ _info.sh   │ │   .sh      │ │   .sh      │
       └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
             │              │              │
             └──────────────┼──────────────┘
                            ▼
                  ┌──────────────────┐
                  │   case_dir/      │   <hostname>_<UTC-timestamp>/
                  │   ├─ 01_*.txt    │
                  │   ├─ 02_*.txt    │
                  │   └─ ...         │
                  └─────────┬────────┘
                            ▼
                  ┌──────────────────┐
                  │ case_dir.tar.gz  │  + case_dir.tar.gz.sha256
                  └──────────────────┘
```

**Design principle:** the orchestrator owns paths and bundling. Modules only know how to *collect* they receive a destination directory as `$1` and write artifacts into it. This loose coupling means new modules drop in without touching the orchestrator.

---

## 🛠 Installation

### Requirements

- Linux host (Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 7+ supported)
- Bash 4.4 or later
- Standard GNU coreutils (`tar`, `sha256sum`, `find`, `awk`)
- **Root or sudo recommended** some artifacts (full auth logs, `lastb`, sudoers) require elevated privileges

### Clone

```bash
git clone https://github.com/WiLL75G/linux-triage-toolkit.git
cd linux-triage-toolkit
chmod +x triage.sh modules/*.sh
```

---

## ▶️ Usage

### Basic run

```bash
sudo ./triage.sh
```

Output is written to `output/<hostname>_<UTC-timestamp>/`, then bundled to a `.tar.gz` with an accompanying `.sha256` hash file.

### Example session

```bash
$ sudo ./triage.sh
[14:22:01Z] Linux Triage Toolkit starting
[14:22:01Z] Case directory: /opt/linux-triage-toolkit/output/ir-host_20260526T142201Z
[14:22:01Z] Running module: 01_system_info
[14:22:01Z]   -> 01_system_info OK
[14:22:02Z] Bundling artifacts -> .../ir-host_20260526T142201Z.tar.gz
[14:22:02Z] Generating SHA256 of bundle (chain of custody)
[14:22:02Z] Done.
```

### Verify bundle integrity

```bash
sha256sum -c output/ir-host_20260526T142201Z.tar.gz.sha256
```

---

## 📦 Module Catalog

| # | Module | Purpose | MITRE ATT&CK | Status |
|---|---|---|---|---|
| 01 | `01_system_info.sh` | Host identity, OS, kernel, timezone | T1082 | ✅ Available |
| 02 | `02_users.sh` | Logged-in users, login history, sudoers | T1087, T1078 | 🔜 Day 2 |
| 03 | `03_processes.sh` | Process tree, deleted-binary detection | T1057 | 🔜 Day 3 |
| 04 | `04_network.sh` | Listeners, connections, ARP, firewall | T1049, T1016 | 🔜 Day 4 |
| 05 | `05_persistence.sh` | Cron, systemd, SSH keys, shell rc files | T1543, T1053, T1098 | 🔜 Day 5 |
| 06 | `06_files.sh` | Recent mods, SUID/SGID, world-writable | T1083, T1222 | 🔜 Day 6 |
| 07 | `07_logs.sh` | auth.log, syslog, journal, bash history | T1070 | 🔜 Day 6 |
| 08 | `08_hashes.sh` | SHA-256 of suspicious binaries | — | 🔜 Day 7 |

---

## 🛡 MITRE ATT&CK Coverage

This toolkit is designed to surface evidence aligned to the following techniques. Coverage expands daily through the build series.

| Tactic | Technique ID | Technique Name | Module |
|---|---|---|---|
| Discovery | T1082 | System Information Discovery | 01 |
| Discovery | T1087 | Account Discovery | 02 |
| Discovery | T1057 | Process Discovery | 03 |
| Discovery | T1049 | System Network Connections Discovery | 04 |
| Discovery | T1016 | System Network Configuration Discovery | 04 |
| Discovery | T1083 | File and Directory Discovery | 06 |
| Persistence | T1543 | Create or Modify System Process | 05 |
| Persistence | T1053 | Scheduled Task / Job | 05 |
| Persistence | T1098 | Account Manipulation | 05 |
| Initial Access | T1078 | Valid Accounts | 02 |
| Defense Evasion | T1070 | Indicator Removal on Host | 07 |
| Defense Evasion | T1222 | File and Directory Permissions Modification | 06 |

---

## 📄 Sample Output

A representative `01_system_info.txt` artifact looks like:

```
=== System Information ===
Collected (UTC): 2026-05-26T14:22:01Z

--- Hostname ---
ir-host

--- Kernel (uname -a) ---
Linux ir-host 5.15.0-91-generic #101-Ubuntu SMP x86_64 GNU/Linux

--- OS release ---
NAME="Ubuntu"
VERSION="22.04.3 LTS (Jammy Jellyfish)"
ID=ubuntu

--- Uptime ---
 14:22:01 up 3 days,  2:14,  1 user,  load average: 0.08, 0.03, 0.01

--- Date / Timezone ---
Tue May 26 14:22:01 UTC 2026
```

Bundle artifact: `ir-host_20260526T142201Z.tar.gz` (≈ 2 KB at Day 1, grows with each module).

---

## 🗓 Build Roadmap

A live record of the 7-day build. Each day adds one module and a documented learning post.

| Day | Date | Scope | Commit |
|---|---|---|---|
| **1** | Tue 26 May 2026 | Project scaffold + `triage.sh` orchestrator + `01_system_info` | ✅ Shipped |
| **2** | Wed 27 May 2026 | `02_users` user, session, and sudoers collection | 🔜 |
| **3** | Thu 28 May 2026 | `03_processes` process tree + deleted-binary detection | 🔜 |
| **4** | Fri 29 May 2026 | `04_network` listeners, established conns, ARP, firewall | 🔜 |
| **5** | Mon 1 Jun 2026 | `05_persistence` cron, systemd, SSH keys, shell rc files | 🔜 |
| **6** | Tue 2 Jun 2026 | `06_files` + `07_logs` file artifacts and log capture | 🔜 |
| **7** | Wed 3 Jun 2026 | `08_hashes` + Ubuntu VM validation + final SOC report | 🔜 |

---

## 📂 Repository Structure

```
linux-triage-toolkit/
├── triage.sh                  # Main orchestrator
├── modules/                   # Drop-in collection scripts
│   └── 01_system_info.sh
├── output/                    # Generated bundles (gitignored)
│   └── .gitkeep
├── docs/                      # Documentation assets
│   └── banner.svg
├── .gitignore
├── LICENSE
└── README.md
```

---

## ⚠️ Limitations & Future Work

**Current limitations:**

- Tested primarily against **Debian/Ubuntu**; RHEL/CentOS paths fall back gracefully but are not yet validated end-to-end.
- Some artifacts (full `auth.log`, `lastb`, `sudoers`) require root privileges. The tool degrades to "not readable" notices rather than failing.
- No remote collection the toolkit is intended for on-host execution. Use `scp` to retrieve the bundle from a compromised host.
- No anti-tampering protection beyond the bundle hash. An attacker with root before collection could alter live evidence.

**Future enhancements being considered:**

- JSON-formatted output mode for SIEM ingestion
- Optional remote artifact upload (SFTP / S3)
- Memory acquisition module (LiME integration)
- Detection signature library known-bad cron entries, suspicious `.bashrc` snippets

---

## Author

**Gokah William**
SOC Analyst (in training) focused on blue-team operations, threat detection, and incident response.

- GitHub: [@WiLL75G](https://github.com/WiLL75G)
- Building a public learning portfolio of SOC tooling and detection work.

---

## License

This project is licensed under the **MIT License** see the [LICENSE](LICENSE) file for full text.

> Built as part of a documented public learning journey toward a SOC Tier 1 Analyst role. Feedback, issues, and pull requests welcomed.
