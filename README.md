<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="160"/>
</p>

<h1 align="center">Termim</h1>

<p align="center">
  <strong>Directory & Context-Aware Terminal History. Lightning-fast, zero-daemon, private.</strong>
</p>

<p align="center">
  <a href="https://github.com/akhtarx/termim/releases/latest"><img src="https://img.shields.io/github/v/release/akhtarx/termim?style=for-the-badge&color=6366f1" alt="Release"></a>
  <a href="https://github.com/akhtarx/termim/stargazers"><img src="https://img.shields.io/github/stars/akhtarx/termim?style=for-the-badge&color=FBBF24" alt="Stars"></a>
  <a href="https://github.com/akhtarx/termim/network/members"><img src="https://img.shields.io/github/forks/akhtarx/termim?style=for-the-badge&color=38bdf8" alt="Forks"></a>
  <a href="https://github.com/akhtarx/termim/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/akhtarx/termim/ci.yml?style=for-the-badge&label=Build" alt="Build Status"></a>
  <a href="https://github.com/akhtarx/termim/issues"><img src="https://img.shields.io/github/issues/akhtarx/termim?style=for-the-badge&color=EF4444" alt="Issues"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/akhtarx/termim?style=for-the-badge&color=475569" alt="License"></a>
</p>

<p align="center">
  <a href="https://akhtarx.github.io/termim/"><strong>🌐 View Live Simulation & Documentation →</strong></a>
</p>

---

## 🚀 Quick Install

**Unix/macOS (Bash, Zsh, Fish):**
```bash
curl -fsSL https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iex (iwr -useb https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.ps1)
```

---

## 🧠 The Problem
Your shell history is a giant, noisy list that doesn't know where you are. You press **Up Arrow** 20 times just to find a `docker` command you ran yesterday, only to be buried under irrelevant garbage from:
- Different side projects
- One-off system settings
- Typos and "noisy" commands

## 🛠️ The Solution: Context-Aware History
Termim isolates your history **per working directory**, giving your terminal a "memory" of where you are.

- **Up Arrow** → Priority access to commands ran in the *current directory*.
- **The Escape Path** → Need a global command? Just keep pressing **Up**. Once you've cycled through your directory context, Termim seamlessly switches to your global history.
- **Contextual Suggestions** → Press **Down Arrow** on a blank prompt to get suggestions based on your project stack and previous commands (e.g., `git status` after `git init`).

---

## 📺 How it works

### 1. Strict Project Isolation
Stop digging through global noise. Termim recognizes your current project context automatically.
```text
~/projects/react-webapp $ [Up Arrow]
> npm run dev          # (Context: React)

~/projects/django-api $ [Up Arrow]
> python manage.py runserver  # (Context: Django)
# Result: Commands from 'react-webapp' are invisible here.
```

> [!NOTE]
> **How Termim Identifies a "Project"**
> Termim binds history strictly to the **absolute filesystem path** of the directory. This guarantees high performance and zero external dependencies (no Git tracking or inode lookups). 
> 
> However, this means that **moving or renaming** a project directory (e.g., from `~/code/foo` to `~/projects/foo`) will start a fresh history context, as the absolute path has changed.

### 2. The Escape Path (Global Fallback)
Need a global command? Just keep pressing Up. Termim swaps the buffer once local history is exhausted.
```text
~/projects/django-api $ [Up Arrow]
> python manage.py runserver
> [Up Arrow Again]     --- Switching to Global ---
> ssh admin@prod-db    # (Global history fallback)
```

### 3. Contextual Suggestions
Hit **Down Arrow** on a blank prompt to get "Next-Move" suggestions based on your project's ecosystem and your recent commands.
```text
~/projects/django-api $ git status
~/projects/django-api $ [Down Arrow]
> git add . && git commit -m "update"  # (Suggested via command transition)
```

### 4. Privacy & Noise Filtering
Termim automatically prunes the "junk" so your history stays pristine.
```text
~/projects/api $ git statsu      # (Pruned: Typo)
~/projects/api $ export KEY=...  # (Redacted: [REDACTED_SECRET])
```

---

## 🏁 Quick Start
1. **Install** via the one-liner above.
2. **Initialize** a directory to start tracking it:
   ```bash
   termim init
   ```
3. **Use your terminal** as usual. Termim works silently in the background.
4. **Recall** commands with **Up Arrow** or open the **Fuzzy Palette** with **Ctrl + P**.

---

## 💎 Why Termim?

| Feature | **Termim** | Atuin | McFly | Native |
| :--- | :---: | :---: | :---: | :---: |
| **Directory Isolation** | **Strict** | Optional | Limited | No |
| **Setup Complexity** | **Zero-Daemon** | Server/Sync | SQLite | None |
| **Windows Support** | **First-Class** | Partial | No | Yes |
| **Privacy Redaction** | **In-Memory** | No | No | No |
| **End-to-End Latency** | **< 20 ms** | ~50ms | ~20ms | < 1ms |

---

## 🛡️ Security & Privacy
Termim **Prioritizes Privacy**. Before any command is saved to disk, our engine attempts to mask common sensitive data:
- **Credentials**: Strips passwords, API keys, and auth tokens.
- **Bearer Tokens**: Redacts Authorization headers and JWTs.
- **Local Only**: All data stays in `~/.termim/`. No telemetry, no cloud, no tracking.
- **OS Quarantine Bypasses**: For a seamless "one-liner" installation, the official install scripts remove the macOS Gatekeeper quarantine bit (`xattr -d com.apple.quarantine`) and Windows Mark-of-the-Web (`Unblock-File`) from the downloaded binary. This allows immediate execution without manual OS overrides. A loud warning is printed when this occurs. If you prefer strict OS-level Gatekeeper enforcement, use the `--build` flag to compile from source locally.

---

## 📖 Feature Overview

Termim is more than just a history filter; it's a context engine.
- **Atomic Continuity**: Every write is protected by `fd-lock`, ensuring zero data corruption across parallel terminal sessions.
- **Contextual Suggestions**: Uses weighted command transitions and ecosystem detection to suggest whether you need `git push` or `npm start` based on your previous action. (No AI required, just fast, deterministic heuristics).
- **Privacy Filtering**: Pattern-based redaction engine attempts to filter common credential formats before they hit your history files.
- **Branch-Aware Context**: (Optional) Tracks git branches to keep branch-specific commands at the top of your stack.
- **Smart Pruning**: Automatically removes typos and failed commands to keep your history "high-signal."

### Keyboard Controls
| Key | Action |
| :--- | :--- |
| **Up Arrow** | Directory History → Global History. |
| **Down Arrow** | Suggestions → Local History. |
| **Ctrl + P** | Fuzzy History Palette (requires `fzf`). |

---

## 🛠️ CLI Command Reference

While Termim handles history automatically, the CLI provides powerful tools for manual management and diagnostics.

### `termim init`
Explicitly mark a directory as a "Boundary".
```bash
# Register current folder as a project context
termim init
```

### `termim suggest`
Generate context-aware suggestions for your next command.
```bash
# Get the top 3 contextual suggestions
termim suggest --limit 3
```

### `termim stats`
Analyze your terminal habits and global command frequency.
```bash
# View usage trends across all projects
termim stats
```

### `termim doctor`
Run a health check on your environment and shell integrations.
```bash
# Verify PATH, binary integrity, and shell hooks
termim doctor
```

### `termim update`
Securely download the latest release from GitHub.
```bash
# Checks for updates and provides a one-liner to upgrade
termim update
```

---

## 📖 Feature Deep Dive

### 🧠 Command Transitions (Weighted History)
Termim doesn't just rank by frequency; it tracks sequential habits. If you always run `npm test` after `npm build`, Termim records this transition and moves `npm test` to the top of your history when you finish a build.

### 🔒 Privacy Filtering (In-Memory Redaction)
Our regex-based scrubbing engine attempts to redact common sensitive strings (passwords, AWS keys, JWTs) before they are written to disk. This happens entirely in-memory with negligible overhead.

### 🛡️ Atomic Continuity
Built with `fd-lock` and true in-place file modifications, Termim ensures that multiple parallel terminal tabs can write to the same history context without race conditions or data corruption.

### 🔄 Symmetrical Shell Parity
Whether you are on Windows PowerShell or macOS Zsh, the logic is identical. Termim provides a 1:1 consistent experience across all supported shells.

---

### 🖥️ Shell Support Matrix

Termim provides a 1:1 symmetrical experience across all major shells. Because shell integration involves complex hooks (prompts, history traversal, keybindings), all integrations are currently considered **Beta** while undergoing extended compatibility testing.

| Shell | Platform | Context Isolation | Fuzzy Palette (`Ctrl+P`) | Contextual Suggestions | Status |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **PowerShell 7+** | Windows | ✅ | ✅ | ✅ | **Beta** |
| **Bash 5.x** | Linux / macOS / WSL | ✅ | ✅ | ✅ | **Beta** |
| **Zsh** | macOS / Linux | ✅ | ✅ | ✅ | **Beta** |
| **Fish** | Linux / macOS | ✅ | ✅ | ✅ | **Beta** |

> [!WARNING]
> **Compatibility Testing Ongoing**
> Modifying shell lifecycles is a minefield. While Termim generally works out-of-the-box, edge cases may arise in environments with heavy shell customizations (e.g., highly customized Oh My Zsh configs, older Bash 4.x environments, nested shells, or non-interactive SSH sessions). If you encounter prompt lagging or history hijacking, please [open an issue](https://github.com/akhtarx/termim/issues).

### 🛡️ Cross-Platform Testing
To ensure the highest reliability possible, Termim's shell hooks are backed by a **cross-platform integration test suite**. On every commit, our CI matrix (Ubuntu, macOS, Windows) spawns real instances of Bash, Zsh, Fish, and PowerShell. The tests emulate command executions and lifecycle hooks via the shell's native APIs, ensuring the history bindings and buffer manipulations work safely across all supported platforms.

---

## ⚡ Performance & Benchmarks

Termim is designed with a strict performance budget. Our goal is **sub-20ms total execution time** (keypress → shell hook → process spawn → filesystem write → shell responsiveness) so that history logging feels instant and invisible.

To verify the core engine's micro-performance, run the built-in, zero-dependency benchmark harness:
```bash
cargo run --release --bin latency_benchmarks
```

### Core Logic Microbenchmarks (Intel Core / Apple Silicon equivalent)
*Note: These measure internal Rust logic latency, not the full OS process spawning overhead.*
- **Path Normalization**: ~96 ns
- **Project Hashing**: ~234 ns
- **Command Sanitization (RegEx Filtering)**: ~2.3 µs
- **Fundamentals Lookup**: ~89 ns

---

## 🧬 Architecture
Termim is designed for **Reliable Continuity.** It uses a zero-daemon Rust core with atomic file operations and deterministic heuristics (ecosystem detection and weighted command transitions) to suggest your next move.

For a deep dive into our technical stack (`fd-lock`, transition ranking, and state machines), see **[ARCHITECTURE.md](ARCHITECTURE.md)**.

---

## 📄 License
Licensed under the **MIT License.**

<p align="center">
  Built by <strong>Md Mim Akhtar</strong> @ AkhtarX Labs
</p>
