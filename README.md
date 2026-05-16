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
- **Predictive Intent** → Press **Down Arrow** on a blank prompt to get "Smart Predictions" based on your project stack (e.g., `git status` after `git init`).

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

### 2. The Escape Path (Global Fallback)
Need a global command? Just keep pressing Up. Termim swaps the buffer once local history is exhausted.
```text
~/projects/django-api $ [Up Arrow]
> python manage.py runserver
> [Up Arrow Again]     --- Switching to Global ---
> ssh admin@prod-db    # (Global history fallback)
```

### 3. Smart Predictions
Hit **Down Arrow** on a blank prompt to get "Next-Move" suggestions based on your behavioral patterns.
```text
~/projects/django-api $ git status
~/projects/django-api $ [Down Arrow]
> git add . && git commit -m "update"  # (Predicted via Markov-chain)
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
| **Core Latency** | **Low-Latency** | ~50ms | ~20ms | < 1ms |

---

## 🛡️ Security & Privacy
Termim is **Privacy-First**. Before any command is saved to disk, our engine masks sensitive data:
- **Credentials**: Strips passwords, API keys, and auth tokens.
- **Bearer Tokens**: Redacts Authorization headers and JWTs.
- **Local Only**: All data stays in `~/.termim/`. No telemetry, no cloud, no tracking.

---

## 📖 Feature Overview

Termim is more than just a history filter; it's a context engine.
- **Atomic Continuity**: Every write is protected by `fd-lock`, ensuring zero data corruption across parallel terminal sessions.
- **State-Aware Predictions**: Uses Markov Chain transitions to predict whether you need `git push` or `npm start` based on your previous action.
- **Privacy Sieve**: Character-based redaction engine ensures secrets never hit your history files.
- **Branch-Aware Context**: (Optional) Tracks git branches to keep branch-specific commands at the top of your stack.
- **Smart Pruning**: Automatically removes typos and failed commands to keep your history "high-signal."

### Keyboard Controls
| Key | Action |
| :--- | :--- |
| **Up Arrow** | Directory History → Global History. |
| **Down Arrow** | Predictions → Local History. |
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
Generate intelligent predictions for your next command.
```bash
# Get the top 3 behavioral suggestions
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

### 🧠 Behavioral Transitions (Markov Model)
Termim doesn't just rank by frequency; it ranks by **probability.** If you always run `npm test` after `npm build`, Termim learns this transition and moves `npm test` to the top of your history when you finish a build.

### 🔒 Privacy Sieve (In-Memory Redaction)
Our character-based scrubbing engine ensures that sensitive strings (passwords, AWS keys, JWTs) never hit your history files. This happens entirely in-memory with negligible overhead.

### 🛡️ Atomic Continuity
Built with `fd-lock`, Termim ensures that multiple parallel terminal tabs can write to the same history context without race conditions or data corruption.

### 🔄 Symmetrical Shell Parity
Whether you are on Windows PowerShell or macOS Zsh, the logic is identical. Termim provides a 1:1 consistent experience across all supported shells.

---

### 🖥️ Shell Support Matrix

Termim provides a 1:1 symmetrical experience across all major shells. All integrations are now **Stable**.

| Shell | Platform | Context Isolation | Fuzzy Palette (`Ctrl+P`) | Smart Predictions | Status |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **PowerShell** | Windows | ✅ | ✅ | ✅ | **Stable** |
| **Bash** | Linux / macOS / WSL | ✅ | ✅ | ✅ | **Stable** |
| **Zsh** | macOS / Linux | ✅ | ✅ | ✅ | **Stable** |
| **Fish** | Linux / macOS | ✅ | ✅ | ✅ | **Stable** |

---

## 🧬 Architecture
Termim is designed for **Reliable Continuity.** It uses a zero-daemon Rust core with atomic file operations and Markov Chain transitions to predict your next move.

For a deep dive into our technical stack (`fd-lock`, predictive engines, and state machines), see **[ARCHITECTURE.md](ARCHITECTURE.md)**.

---

## 📄 License
Licensed under the **MIT License.**

<p align="center">
  Built by <strong>Md Mim Akhtar</strong> @ AkhtarX Labs
</p>
