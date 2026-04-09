<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="200"/>
</p>

<h1 align="center">Termim</h1>

> **Find the command you ran yesterday in 1 second.**

Stop fighting with your Up-Arrow key. Termim makes your shell **project-aware**, so you only see the commands that actually matter *right now*.

<p align="center">
  <a href="https://github.com/akhtarx/termim/releases"><img src="https://img.shields.io/github/v/release/akhtarx/termim?style=for-the-badge&color=7C3AED" alt="Release"></a>
  <a href="https://github.com/akhtarx/termim/stargazers"><img src="https://img.shields.io/github/stars/akhtarx/termim?style=for-the-badge&color=FBBF24" alt="Stars"></a>
  <a href="https://github.com/akhtarx/termim/issues"><img src="https://img.shields.io/github/issues/akhtarx/termim?style=for-the-badge&color=EF4444" alt="Issues"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/akhtarx/termim?style=for-the-badge&color=475569" alt="License"></a>
</p>

---

## 🧠 The Problem

Your Up-Arrow key should be your best friend. But usually, it's a mess. 

You press it 20 times just to find that one `docker` or `cargo` command you ran yesterday, only to see irrelevant garbage from:
- A different side project you were working on
- System settings you changed once
- Typoes and "noisy" commands you'll never run again

**Standard history is a giant, noisy list that doesn't know where you are.**

## ⚡ The Fix

Termim isolates your history **per project**. It creates a "boundary" for your terminal so "Environment Bleeding" becomes impossible.

- **Up Arrow** → Instantly shows only commands you ran in the *current* project.
- **Down Arrow** → Escapes to global history when you actually need it.
- **Smart Predictions** → Guesses what you’ll do next based on your actual habits.

## 💥 What it feels like

- **Zero Noise**: No more digging through 1,000 irrelevant commands.
- **Instant Recall**: Find that "yesterday command" in exactly 1 second.
- **Safety**: Stop accidentally running a `production` command in a `dev` folder because it was at the top of your history.

> **Termim = Context for your terminal.**

---

<!-- Replace this with a demo GIF showing: 
1. Pressing Up Arrow and getting a mess ❌ 
2. Pressing Up Arrow and getting the exact command you need ✅ 
-->
## 📺 Demo
![Termim Demo Placeholder](assets/logo.png)

---

## 💎 Why Termim? (Core Differentiators)

Termim isn't just another history tool; it's a **context-switching accelerator.**

### 1. Hard-Locked Context
Unlike other tools that offer "fuzzy" suggestions from your entire history, Termim **identifies the specific project boundary.** Your `Up Arrow` is locked to that project until you intentionally "escape" to global history. This prevents **"Environment Bleeding"** where you accidentally run a command from a different project.

### 2. Zero-Daemon, Zero-DB Architecture
Termim has **no background services.**
- **Atuin/McFly**: Often rely on background databases (SQLite) which can incur multi-millisecond latency and sync overhead.
- **Termim**: Uses high-performance plain-text isolation. It is as lightweight as the shell itself.

### 3. Reactive Behavioral Learning
Termim doesn't just rank by frequency; it ranks by **probability.** By observing your "Command Transitions" (Markov Chain), it predicts whether you need `git push` or `npm test` based on what you *just* finished doing.

---

## ⚡ Technical Core
**Termim v1.0.7** converts standard, chronological shell history into a **behavioral contextual memory layer**. It is designed for engineers seeking project-local isolation with negligible overhead.

- **🔄 Symmetrical Navigation**: A deterministic state machine providing 1:1 parity between PowerShell, Bash, Zsh, and Fish.
- **🚀 Fundamentals Engine**: A static, zero-latency dispatch registry providing O(1) follow-up suggestions without disk I/O.
- **1000x Adaptive Behavioral Logic**: High-coefficient Markov Chain transitions prioritize your unique behavioral patterns.
- **Deterministic Context Isolation**: Normalization-based project detection across Rust, Node, and POSIX environments.
- **Atomic Concurrency**: Powered by **Universal Advisory Locking (`fd-lock`)**. Ensures data integrity across parallel terminal instances.
- **Minimalist Latency**: Dependency-free core logic achieves an average latency of **~15ms**.
- **Privacy Sieve**: A character-based redaction engine masks credentials and secrets in-memory.

---

## 📊 Strategic Positioning

| Feature | **Termim** | Atuin | McFly | HSTR | Native |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Shell Parity (Symmetry)**| ✅ | ❌ | ❌ | ❌ | ❌ |
| **Fundamentals Engine**| ✅ | ❌ | ❌ | ❌ | ❌ |
| **Project Isolation** | ✅ | ⚠️ | ⚠️ | ❌ | ❌ |
| **Behavioral Intel** | ✅ | ⚠️ | ✅ | ❌ | ❌ |
| **Zero-Daemon** | ✅ | ❌ | ✅ | ✅ | ✅ |
| **Zero-Database** | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Native Windows** | ✅ | ⚠️ | ❌ | ❌ | ✅ |
| **Privacy Sieve** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Success-Only Learning** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Latency Moat** | **~15ms** | > 50ms | > 20ms | < 10ms | < 1ms |

---

## 📖 Usage & Navigation

| Key | Action |
| :--- | :--- |
| **Up Arrow** | Cycle through project-specific history → Global History. |
| **Down Arrow** | Navigate from Global history back to Project-local history and Predictions. |
| **Ctrl + P** | Open the interactive fuzzy-search history palette (requires `fzf`). |

### CLI Command Reference

| Command | Description |
| :--- | :--- |
| `termim init` | Initialize Termim boundary for the current project. |
| `termim query` | List ranked history for the current project. |
| `termim suggest` | Get intelligent, weighted command suggestions for the stack. |
| `termim stats` | View global usage statistics and behavioral trends. |
| `termim doctor` | Run a diagnostic health check of your installation. |
| `termim update` | Check for the latest version of Termim from GitHub. |
| `termim clear`  | Clear all Termim data (history, registry, and stats). |

---

## 🏁 Universal Shell Support

| Shell | Platform | Up/Down Arrow | Ctrl+P (Palette) | Status |
| :--- | :--- | :--- | :--- | :--- |
| **PowerShell** | Windows | Stable ✅ | Stable ✅ | Production |
| **Bash** | Git Bash / Linux | Stable ✅ | Stable ✅ | Production |
| **Zsh** | macOS / Unix | Stable ✅ | Beta ⚠️ | Production |
| **Fish** | macOS / Unix | Stable ✅ | Beta ⚠️ | Production |

---

## 🐚 Shell Authentication Matrix (v1.0.7)

| Feature | PowerShell | Zsh | Bash | Fish | Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Exit Status Capture** | ✅ (`prompt`) | ✅ (`precmd`) | ✅ (`PROMPT_CMD`) | ✅ (`postexec`) | **Authentic** |
| **Markov Context (`--prev`)**| ✅ | ✅ | ✅ | ✅ | **Authentic** |
| **Success-Only Logging** | ✅ | ✅ | ✅ | ✅ | **Authentic** |
| **Predictive Navigation** | ✅ | ✅ | ✅ | ✅ | **Authentic** |
| **Performance Moat** | ✅ | ✅ | ✅ | ✅ | **Authentic** |

---

## 🧬 Architecture

Termim v1.0.7 is built on the principle of **Reliable Continuity.** Every architectural decision—from binary startup to file pruning—is optimized for sub-20ms execution and 100% data integrity.

### 1. Performance Moat (Zero-Library Tax)
Termim eliminates the "Library Startup Tax" by using zero-dependency core logic for its most critical paths.
- **No Heavy RegEx**: A manual, multi-token character sieve replaces expensive regex for credential redaction (Logic cost: <0.5ms).
- **No Lazy State**: Eliminating `once_cell` and other lazy-init patterns to ensure immediate binary execution.

### 2. Concurrency (Universal Locking)
Every file-write operation is protected by **Universal Advisory Locking (`fd-lock`)**.
- **Atomic Harmony**: Prevents race conditions between multiple parallel terminal sessions.
- **Safety**: Atomic write-rename logic ensures that history files are never corrupted.

### 3. Adaptive Intelligence (Markov Weighting)
Termim uses a **Unified Weighted Ranking Engine** to prioritize history and predictions:
- **Behavioral Transitions**: High-coefficient weighting for literal next-step habits based on Markov Chain analysis.
- **Ecosystem Defaults**: O(1) static dispatch for stack-defining commands (e.g., `git init` -> `git status`).
- **Project Context**: Frequency-based ranking within the local project boundary.

### 4. Deterministic Shell Hand-off
All four shell hooks share a synchronized state machine logic. By tracking the `_TERMIM_IDX` across project cache boundaries, Termim manages the transition from project-local history into the global shell history stack.

---

## 🛡️ Security & Privacy
Termim is designed with a **Privacy-First** architecture. 

### Manual Redaction Sieve
Before any command is saved to disk, Termim's **Zero-Library Sieve** scrubs it for sensitive data:
- **Credentials**: `mim:password@host` becomes `mim:***@host`.
- **Multi-Token Secrets**: Catching `KEY=secret`, `TOKEN:secret`, and `PASSWORD secret` in a single line.
- **Local Isolation**: All data stays on your machine at `~/.termim/`. No telemetry. No cloud.

---

## 📦 Installation

### 💻 Windows (PowerShell & Git Bash)
```powershell
git clone https://github.com/akhtarx/termim.git; cd termim; .\installer\install.ps1
```

### 🍎 macOS & 🐧 Linux (Zsh, Bash, Fish)
```bash
git clone https://github.com/akhtarx/termim.git && cd termim && bash installer/install.sh
```

---

## 🤝 Contributing
We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for local development setup.

## 📄 License
Termim is licensed under the **MIT License.** See [LICENSE](LICENSE) for more details.

---
<p align="center">
  Built with ❤️ by <strong>Md Mim Akhtar</strong><br/>
  Assisted by <strong>AI Tools</strong><br/>
  Part of the <strong>AkhtarX Labs</strong>
</p>
