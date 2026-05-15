<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="200"/>
</p>

<h1 align="center">Termim</h1>

> **Find the command you ran yesterday in 1 second.**

Stop fighting with your Up-Arrow key. Termim makes your shell **directory & context-aware**, so you only see the commands that actually matter *right now*.

<p align="center">
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

## 🛠️ The Solution

Termim isolates your history **per working directory**. It creates a context for your terminal so "Environment Bleeding" becomes impossible.

- **Up Arrow** → Instantly shows only commands you ran in the *current working directory*.
- **Escape Path** → Termim tracks your session index. Once you've cycled through all directory-specific commands (the "directory context"), hitting **Up Arrow again** triggers a context escape. It seamlessly swaps the buffer to your standard global history. You never lose access to your old commands; they just wait behind the directory context.
- **Down Arrow** → Trigger **Smart Predictions** (from a blank prompt) or navigate back from global history into your directory context (if you exceed directory history to global history by pressing arrow up).

## 💥 What it feels like

- **Zero Noise**: No more digging through 1,000 irrelevant commands.
- **Faster Recall**: Find that "yesterday command" in exactly 1 second.
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

Termim isn't just another history tool; it's a **context-switching aid.**

### 1. Directory Context Awareness
Unlike other tools that offer "fuzzy" suggestions from your entire history, Termim **identifies the specific directory context.** Your `Up Arrow` is locked to that context until you intentionally "escape" to global history. This prevents **"Environment Bleeding"** where you accidentally run a command from a different folder.

### 2. Lightweight Architecture
Termim has **no background services.**
- **Isolation**: Uses high-performance plain-text isolation. It is as lightweight as the shell itself.

### 3. Reactive Behavioral Learning
Termim doesn't just rank by frequency; it ranks by **probability.** By observing your "Command Transitions", it predicts whether you need `git push` or `npm test` based on what you *just* finished doing.

---

## ⚡ Technical Core
**Termim** converts standard, chronological shell history into a **behavioral contextual memory layer**. It is designed for engineers seeking project-local isolation with negligible overhead.

- **🧠 Multi-Dimensional Context**: Distinguishes between Git branches and prioritizes recovery commands after failures.
- **🔄 Symmetrical Navigation**: A deterministic state machine providing 1:1 parity between PowerShell, Bash, Zsh, and Fish.
- **⚙️ Static Dispatch**: A zero-latency dispatch registry providing follow-up suggestions without unnecessary disk I/O.
- **Adaptive Behavioral Logic**: Markov Chain transitions prioritize your unique behavioral patterns.
- **Path-Based Isolation**: Normalization-based directory detection across Rust, Node, and POSIX environments.
- **Atomic Concurrency**: Powered by **Universal Advisory Locking (`fd-lock`)**. Ensures data integrity across parallel terminal instances.
- **Optimized Performance**: Dependency-free core logic achieves low-latency execution.
- **Privacy Sieve**: A character-based redaction engine masks credentials and secrets in-memory.

---

## 📊 Strategic Positioning

| Feature | **Termim** | Atuin | McFly | HSTR | Native |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Shell Parity (Symmetry)**| ✅ | ❌ | ❌ | ❌ | ❌ |
| **Static Dispatch**| ✅ | ❌ | ❌ | ❌ | ❌ |
| **Directory Isolation** | ✅ | ⚠️ | ⚠️ | ❌ | ❌ |
| **Behavioral Intel** | ✅ | ⚠️ | ✅ | ❌ | ❌ |
| **Zero-Daemon** | ✅ | ❌ | ✅ | ✅ | ✅ |
| **Native Windows** | ✅ | ⚠️ | ❌ | ❌ | ✅ |
| **Privacy Sieve** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Failure-Aware Logic** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Performance** | **Fast** | > 50ms | > 20ms | < 10ms | < 1ms |

---

## 📖 Usage & Navigation

| Key | Action |
| :--- | :--- |
| **Up Arrow** | Cycle through directory-specific history → Global History. |
| **Down Arrow** | Navigate from Global history back to directory-local history and Predictions. |
| **Ctrl + P** | Open the interactive fuzzy-search history palette (requires `fzf`). |

### CLI Command Reference

| Command | Description |
| :--- | :--- |
| `termim init` | Initialize Termim boundary for the current directory. |
| `termim query` | List ranked history for the current directory. |
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

## 🐚 Shell Authentication Matrix

| Feature | PowerShell | Zsh | Bash | Fish | Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Exit Status Capture** | ✅ | ✅ | ✅ | ✅ | **Authentic** |
| **Git Branch Detection**| ✅ | ✅ | ✅ | ✅ | **Authentic** |
| **Markov Context (`--prev`)**| ✅ | ✅ | ✅ | ✅ | **Authentic** |
| **State-Aware Logic** | ✅ | ✅ | ✅ | ✅ | **Authentic** |
| **Performance** | ✅ | ✅ | ✅ | ✅ | **Authentic** |

---

## 🧬 Architecture

Termim is built on the principle of **Reliable Continuity.** Every architectural decision—from binary startup to file pruning—is optimized for low-latency execution and 100% data integrity.

### 1. Robust Operations (Safe Local Operations)
Termim protects your data and ensures it remains private and secure locally.
- **Optimized RegEx**: Precise regular expressions for robust credential redaction before saving to disk.
- **Standardized State Initialization**: Uses fast and reliable lazy initialization patterns via `once_cell` to ensure efficient, safe startup and single-time compilation.

### 2. Concurrency (Universal Locking)
Every file-write operation is protected by **Universal Advisory Locking (`fd-lock`)**.
- **Atomic Harmony**: Prevents race conditions between multiple parallel terminal sessions.
- **Safety**: Atomic write-rename logic ensures that history files are never corrupted.

### 3. Adaptive Intelligence (Markov Weighting)
Termim uses a **Unified Weighted Ranking Engine** to prioritize history and predictions:
- **Behavioral Transitions**: High-coefficient weighting for literal next-step habits based on Markov Chain analysis.
- **Ecosystem Defaults**: Static dispatch for stack-defining commands (e.g., `git init` -> `git status`).
- **Directory Context**: Frequency-based ranking within the local directory boundary.

### 4. Deterministic Shell Hand-off
All four shell hooks share a synchronized state machine logic. By tracking the `_TERMIM_IDX` across directory cache boundaries, Termim manages the transition from directory-local history into the global shell history stack.

---

## 🛡️ Security & Privacy
Termim is designed with a **Privacy-First** architecture. 

### Smart Redaction
Before any command is saved to disk, Termim's scrubbing engine removes sensitive patterns from the data:
- **Credentials & Tokens**: Strips out passwords, keys, and authorization headers.
- **Multi-Token Secrets**: Recognizes various common secret and token patterns in-memory.
- **Local Isolation**: All data stays on your machine at `~/.termim/`. No telemetry. No cloud.

---

## 📦 Installation

### 🍎 macOS & 🐧 Linux (Zsh, Bash, Fish)
```bash
curl -fsSL https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.sh | bash
```

### 💻 Windows (PowerShell & Git Bash)
```powershell
iex (iwr -useb https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.ps1)
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
