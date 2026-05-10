# 🚀 Termim v1.1.1: The Hardening Patch

v1.1.1 is a targeted patch release focused entirely on production robustness. It eliminates the concurrency data-loss risks identified in v1.1.0, significantly strengthens the redaction engine, bounds memory usage for large history files, and expands the `termim doctor` diagnostic command into a proper health-check tool.

---

## ✨ What's New in v1.1.1?

### ⚛️ Atomic Writes Everywhere
`append_to_file_locked` and `prune_log` now use **tempfile + atomic rename** instead of in-place seek/truncate. This eliminates the partial-write data loss window that existed under concurrent terminal sessions (multiple shells logging to the same project file simultaneously).

### 🔒 Expanded Redaction Engine
The Privacy Sieve now catches significantly more secret patterns before they touch disk:
- **Shell assignments**: `export AWS_KEY=abc123` → `export AWS_KEY=[REDACTED]`
- **Header values**: `Authorization: Bearer sk-…` → `Authorization: Bearer [REDACTED]`
- **Token prefixes**: GitHub PATs (`ghp_`), OpenAI (`sk-`), AWS (`AKIA…`), Slack (`xox…`), JWT (`eyJ…`) → `[REDACTED_TOKEN]`
- **Base64 blobs**: Long base64 strings (≥20 chars) after `=` → `=[REDACTED_B64]`

### 🧠 Memory-Efficient History Reads
Replaced full-file `read_to_string` with a **circular-buffer tail reader** (last 500 lines). History queries now use O(N) bounded RAM regardless of how large a history file grows.

### 🛡️ TOCTOU-Safe Prune + Hard Size Cap
File size checks are now performed **inside** the write lock (not before it), closing the time-of-check / time-of-use race window. A hard **512 KB file size cap** is enforced on every prune cycle, preventing runaway history growth.

### 🩺 Enhanced `termim doctor`
The diagnostic command is now a proper health-check tool:
- ✅ Write **permissions check** on `~/.termim/projects/`
- ✅ **File health report** with line count, size, and cap warning
- ✅ **Plugin sanity check** — flags missing or empty shell plugin files
- ✅ **Self-latency benchmark** — measures SHA-256 hash cost vs `<5ms` target
- ✅ **Pass/fail summary** at the end

---

## 🛠️ Cumulative Highlights (v1.1.x series)
- **PowerShell Memory Leak Fix**: Auto-disposal of .NET Runspaces on exit.
- **Race-Free Advisory Locking**: Metadata checks secured inside the write lock.
- **Zero Git Forking**: Prompt-level branch caching eliminates subprocess forks on Arrow presses.
- **Multi-Dimensional Context**: Failure-state awareness + Git branch isolation.
- **Zero-Daemon / Zero-DB**: Sub-12ms execution on every keystroke.

---

## 🏁 How to Install / Update

### Windows (PowerShell)
```powershell
git clone https://github.com/akhtarx/termim.git; cd termim; .\installer\install.ps1
```

### macOS & Linux (Zsh, Bash, Fish)
```bash
git clone https://github.com/akhtarx/termim.git && cd termim && bash installer/install.sh
```

---

> **Full changelog**: See [CHANGELOG.md](CHANGELOG.md) for a complete history of all changes.

**Built with ❤️ by Md Mim Akhtar | Part of the AkhtarX Labs.**
