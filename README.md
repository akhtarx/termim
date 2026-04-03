<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="200"/>
</p>

<h1 align="center">Termim</h1>

<p align="center">
  <strong>Your terminal remembers per project.</strong><br/>
  A high-performance context-switching layer for shell history.
</p>

<p align="center">
  <a href="https://github.com/akhtarx/termim/releases"><img src="https://img.shields.io/github/v/release/akhtarx/termim?style=for-the-badge&color=7C3AED" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/akhtarx/termim?style=for-the-badge&color=3B82F6" alt="License"></a>
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/Changelog-v1.0.1-4C1D95?style=for-the-badge" alt="Changelog"></a>
  <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge&color=10B981" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/Rust-2021-orange.svg?style=for-the-badge&color=EA580C" alt="Rust 2021">
</p>

---

## 🧠 The Problem
Standard shell history is fundamentally broken. It is a single, massive, chronological list that mixes every project and work session into a single noisy stream. 
- **Mixing projects = Noise**
- **Recall cost = High**
- **Ctrl+R = A workaround, not a solution**

## ⚡ The Moat: Systems Thinking
**Termim** converts your global shell history into a **contextual memory layer**. It is built for engineers who switch contexts frequently and demand zero impact on terminal performance.

- **Project Isolation**: History is automatically segregated by project root. `Up Arrow` provides context-specific commands for your current work.
- **Zero-Daemon / Zero-DB**: No background services. No complex databases. Termim integrates directly into native shell hooks and uses transparent, plain-text filesystem isolation.
- **Native Speed (0ms Lag)**: Written in Rust for near-instant execution. It is designed to feel identical to native shell responsiveness.
- **No Project Pollution**: Termim doesn't litter your project folders with `.history` or `.termim` files. All data is managed centrally in your user profile.

---

## 📊 Strategic Positioning

| Feature | Termim | Native Ctrl+R | Autosuggest | Atuin | McFly | HSTR |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Project-Aware History** | ✅ | ❌ | ❌ | ❌ | ⚠️ | ❌ |
| **Native Execution Speed** | ✅ | ✅ | ⚠️ | ❌ | ⚠️ | ✅ |
| **No Background Daemon** | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| **Zero-Database (Text-based)** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Hard-Locked Isolation** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 🌊 A Day in the Life with Termim
Imagine you are switching between a **React frontend** and a **Rust backend**:

1. **Frontend Context**: `cd ~/dev/my-app-ui`
   - Press `Up Arrow`: You see `npm run dev`, `vitest`, and `tailwind build`.
   - Your global history noise (`cargo build`, `docker-compose up`) is **filtered out**.
2. **The Context Shift**: `cd ~/dev/my-app-api`
   - Instantly, `Up Arrow` shows `cargo run`, `sqlx migrate`, and `tokio-console`.
3. **The Frictionless Escape**: You need a hidden command from another project?
   - Keep pressing `Up Arrow`. Once project-specific history is exhausted, Termim seamlessly transitions into your **global shell history**.

---

## 📖 Usage & Navigation

| Key | Action |
| :--- | :--- |
| **Up Arrow** | Cycle through project-specific history. |
| **Down Arrow** | Cycle forward or restore the original input. |
| **Ctrl + P** | Open the interactive fuzzy-search history palette (requires `fzf`). |

### CLI Command Reference

| Command | Description |
| :--- | :--- |
| `termim init` | Register the current directory as a project root. |
| `termim query` | List ranked history for the current project. |
| `termim suggest` | Get intelligent command suggestions for the project stack. |
| `termim stats` | View global usage statistics and trends. |
| `termim doctor` | Run a diagnostic health check of your installation. |

---

## 🏁 Shell Support Matrix

| Shell | Environment | Up/Down Arrow | Ctrl+P (Palette) | Status |
| :--- | :--- | :--- | :--- | :--- |
| **PowerShell** | Windows | Stable ✅ | Stable ✅ | Production |
| **Bash** | Git Bash / Linux | Stable ✅ | Stable ✅ | Production |
| **Zsh** | macOS / Unix | Stable ✅ | Beta ⚠️ | Production |
| **Fish** | macOS / Unix | Stable ✅ | Beta ⚠️ | Production |

---

## 📦 Troubleshooting
- **Commands not saving?** Run `termim doctor` to check if your registry is writeable.
- **Up Arrow feels like default?** Ensure you have sourced the integration in your profile (`.zshrc`, `Microsoft.PowerShell_profile.ps1`).
- **Git Bash issues?** Ensure `winpty` is installed for the best `fzf` experience.

---

---

## 🛡️ Security & Privacy
Termim is designed with a **Privacy-First** architecture. 

### Automatic Redaction
Before any command is saved to disk, Termim's **Redaction Engine** scrubs it for sensitive data using high-performance regex:
- **Credentials**: `https://user:password@host` becomes `https://user:***@host`.
- **Secrets**: Environment variables like `API_KEY`, `TOKEN`, `SECRET`, and `PASSWORD` are automatically masked.
- **Local Isolation**: All data stays on your machine at `~/.termim/`. No data ever leaves your computer.

## 🧬 How it Works
Termim uses a **Shadow Registry** system to manage project history without polluting your source code.

1. **Recursive Marker Discovery**: When you run a command, Termim identifies the current project root using explicit markers (`.git`, `package.json`, `Cargo.toml`, etc.) or your manual `termim init` registry.
2. **Contextual Hashing**: The project root is hashed to a unique identifier. History is stored in isolated files within `~/.termim/projects/`.
3. **Direct-to-Disk Logging**: Commands are sanitized (redacting secrets/keys) and appended directly to the project-specific history file with zero intermediate layers.
4. **Frictionless Escape**: Navigation is isolated to project history first. When the project history is exhausted, Termim seamlessly falls back to global shell history.

---

## 🚀 Strategic Roadmap
- **Phase 1 (Current)**: High-performance project isolation and cross-shell navigation.
- **Phase 2 (Next)**: **Contextual Ranking**. Weighting history by frequency and "Success Signals" (Exit Codes).
- **Phase 3 (Vision)**: **Terminal Statefulness**. Command reuse patterns and workflow shortcuts based on project-wide intelligence.

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
