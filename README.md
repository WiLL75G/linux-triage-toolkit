# linux-triage-toolkit

A simple Bash tool that collects evidence from a Linux host during a security incident. When a computer is hacked, this tool grabs the important information fast, before it disappears.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/shell-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Modules Shipped](https://img.shields.io/badge/modules-8%20of%208-brightgreen.svg)](https://github.com/WiLL75G/linux-triage-toolkit/tree/main/modules)
[![MITRE ATT&CK](https://img.shields.io/badge/MITRE-ATT%26CK%20mapped-red.svg)](https://attack.mitre.org/)

---

## What it does

You run one command. The tool answers the questions a SOC analyst asks first:

1. Who is logged in right now?
2. What is running?
3. What is this host talking to on the network?
4. How would an attacker come back after a reboot?
5. What files changed recently?
6. What do the logs say?
7. What are the file hashes for threat intel?

The answers are saved to a folder, compressed into a `.tar.gz` file, and signed with a SHA-256 hash so nothing can be changed without detection.

That last step is the difference between notes and evidence. A collection anyone could alter afterward is worthless in an investigation; a hash-signed bundle is defensible. The tool treats chain of custody as part of the job, not an afterthought.

---

## Why it matters

When a Linux computer is compromised, evidence disappears fast. Processes end. Network connections close. Attackers delete their tracks.

This tool captures that evidence in seconds, using only Bash and tools that ship with every Linux system. No installation, no dependencies, no configuration. That constraint is deliberate: during a live incident you cannot assume you are allowed to install anything on the compromised host, so a triage tool that needs nothing beyond the base system is the one you can actually run when it counts.

Every check is mapped to a [MITRE ATT&CK](https://attack.mitre.org/) technique so the output speaks the same language as commercial security tools.

---

## How to use it

Clone the repo, make the scripts executable, and run:

```bash
git clone https://github.com/WiLL75G/linux-triage-toolkit.git
cd linux-triage-toolkit
chmod +x triage.sh modules/*.sh
sudo ./triage.sh
```

The output lands in `output/<hostname>_<timestamp>/` and is bundled as a `.tar.gz` with a `.sha256` file next to it.

---

## What each module collects

| # | Module | Answers the question | Status |
|---|---|---|---|
| 01 | [`01_system_info.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/01_system_info.sh) | What machine is this? | Shipped |
| 02 | [`02_users.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/02_users.sh) | Who is on it? | Shipped |
| 03 | [`03_processes.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/03_processes.sh) | What is running? | Shipped |
| 04 | [`04_network.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/04_network.sh) | What is it talking to? | Shipped |
| 05 | [`05_persistence.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/05_persistence.sh) | How would the attacker come back? | Shipped |
| 06 | [`06_files.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/06_files.sh) | What files look suspicious? | Shipped |
| 07 | [`07_logs.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/07_logs.sh) | What do the logs say? | Shipped |
| 08 | [`08_hashes.sh`](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/modules/08_hashes.sh) | What are the file hashes for threat intel? | Shipped |

All 8 modules shipped.

---

## Example output

The signature check is a hunt for malware that deletes itself from disk but keeps running in memory:

```
--- Processes with deleted binaries ---
PID 4471 -> /tmp/x (deleted)
  cmdline: /tmp/x --beacon 45.33.32.156:4444
```

Traditional antivirus would miss this. The tool catches it by reading `/proc/<pid>/exe`, where the Linux kernel still remembers where the process came from. That is the whole idea in one example: the evidence an attacker thinks they destroyed is often still readable if you know where the system keeps it.

---

## What I learned building this

- How incident responders think about evidence and time
- Writing Bash that fails safely and clearly
- Reading Linux internals like `/proc` the way real forensics tools do
- Mapping every check to [MITRE ATT&CK](https://attack.mitre.org/) so the output is useful to other analysts
- Shipping one small piece each week for real, in public, on GitHub

---

## Project status

Built one module per week, in public. All 8 of 8 modules are complete: system info, users, processes, network, persistence, files, logs, and file hashing, each mapped to MITRE ATT&CK and bundled with a SHA-256 chain-of-custody hash.

---

Currently looking for Tier 1 SOC roles at remote-friendly MSSPs. Open to conversations, reach out on LinkedIn or through the [issues page](https://github.com/WiLL75G/linux-triage-toolkit/issues).

---

## License

MIT. See [LICENSE](https://github.com/WiLL75G/linux-triage-toolkit/blob/main/LICENSE).
