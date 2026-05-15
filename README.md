<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="160"/>
</p>

<h1 align="center">Termim</h1>

<p align="center">
  <strong>Directory & Context-Aware Terminal History. Lightning-fast, zero-daemon, private.</strong>
</p>

<p align="center">
  <a href="https://github.com/akhtarx/termim/stargazers"><img src="https://img.shields.io/github/stars/akhtarx/termim?style=for-the-badge&color=FBBF24" alt="Stars"></a>
  <a href="https://github.com/akhtarx/termim/issues"><img src="https://img.shields.io/github/issues/akhtarx/termim?style=for-the-badge&color=EF4444" alt="Issues"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/akhtarx/termim?style=for-the-badge&color=475569" alt="License"></a>
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

- **Up Arrow** → Instantly shows only commands ran in the *current directory*.
- **The Escape Path** → Need a global command? Just keep pressing **Up**. Once you've cycled through your directory context, Termim seamlessly switches to your global history.
- **Predictive Intent** → Press **Down Arrow** on a blank prompt to get "Smart Predictions" based on your project stack (e.g., `git status` after `git init`).

---

## 📺 How it works
```text
~/projects/api-server $ [Up Arrow]
> npm run dev          # Directory history
> git commit -m "fix"  # Directory history
> [Up Arrow Again]     --- Switching to Global ---
> ssh prod-server      # Global history
> brew update          # Global history
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
| **Startup Latency** | **< 5ms** | ~50ms | ~20ms | < 1ms |

---

## 🛡️ Security & Privacy
Termim is **Privacy-First**. Before any command is saved to disk, our engine masks sensitive data:
- **Credentials**: Strips passwords, API keys, and auth tokens.
- **Bearer Tokens**: Redacts Authorization headers and JWTs.
- **Local Only**: All data stays in `~/.termim/`. No telemetry, no cloud, no tracking.

---

## 📖 Feature Overview

| Key | Action |
| :--- | :--- |
| **Up Arrow** | Directory History → Global History. |
| **Down Arrow** | Predictions → Local History. |
| **Ctrl + P** | Fuzzy History Palette (requires `fzf`). |

### Shell Support
- **PowerShell** (Windows) - Stable
- **Bash** (Linux/WSL) - Stable
- **Zsh** (macOS) - Stable (Palette in Beta)
- **Fish** (Unix) - Stable (Palette in Beta)

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
