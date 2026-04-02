<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="200"/>
</p>

<h1 align="center">Termim</h1>

<p align="center">
  <strong>Industry-Grade Project-Aware Terminal context engine v1.0.0</strong>
</p>

<p align="center">
  <a href="https://github.com/akhtarx/termim/releases"><img src="https://img.shields.io/github/v/release/akhtarx/termim?style=for-the-badge&color=7C3AED" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/akhtarx/termim?style=for-the-badge&color=3B82F6" alt="License"></a>
  <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge&color=10B981" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/Rust-2021-orange.svg?style=for-the-badge&color=EA580C" alt="Rust 2021">
</p>

<p align="center">
  <a href="#-why-termim">Why Termim?</a> •
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-contributing">Contributing</a>
</p>

---

**Termim** is a high-performance terminal enhancement that replaces your monolithic shell history with an **Industrial-Grade Context Engine.** It understands where you are, what you're building, and provides instant access to the right commands with **0ms lag.**

## 🏁 Why Termim?

Other history tools are slow, bulky, or pollute your folders. Termim achieves the "Silver Bullet" of productivity:

- **0ms Lag (Native Mastery)**: Termim upgrades your shell's native history engine by swapping buffers in real-time. Absolute binary speed. ⚡
- **Universal Windows Architecture**: **One-click installation** for both PowerShell and Git Bash on Windows. 🛡️
- **Zero-Pollution Philosophy**: No hidden `.termim` markers or `.history` files are ever created in your folders. 🧼
- **Zero-Daemon Architecture**: No background processes, no databases, no maintenance. Just pure Rust performance. 🛡️
- **Context-Aware IQ**: Automatically identifies 34+ stacks (Node, Rust, Go, Python, Docker, etc.) and suggests relevant commands without configuration.

## 🏁 Project Support Matrix

| Shell | Environment | Status |
| ----- | ----------- | ------ |
| **PowerShell** | Windows (Terminal/VSCode) | **Production Stable** ✅ |
| **Git Bash** | Windows (MinTTY) | **Production Stable** ✅ |
| **Zsh** | Unix / macOS / WSL / MSYS2 | **Experimental (Alpha)** 🧪 |
| **Fish** | Unix / macOS / WSL / MSYS2 | **Experimental (Alpha)** 🧪 |
| **Bash** | Linux / macOS | **Experimental (Alpha)** 🧪 |

---

## 🚀 Features

- **Fuzzy Search Palette**: Press `Ctrl+P` (requires `fzf`) to search your project history in a premium popup.
- **Project Isolation**: Your history is segregated by project-root. No more searching through unrelated commands.
- **Global Registry**: `termim init` registers projects globally, keeping your source code 100% pristine.
- **Cross-Shell Architecture**: Universal integration suite for all major shells.

---

## 📦 Installation

### Windows (Universal PowerShell/Git Bash)
1. Open PowerShell and run:
   ```powershell
   git clone https://github.com/akhtarx/termim.git
   cd termim
   .\installer\install.ps1
   ```
2. **PowerShell**: Ready immediately!
3. **Git Bash**: Restart or run `source ~/.bashrc` to activate.

### Unix / macOS (Zsh/Bash/Fish)
1. Open your terminal and run:
   ```bash
   git clone https://github.com/akhtarx/termim.git
   cd termim
   bash installer/install.sh
   ```
2. Restart your shell to activate.

---

## 📖 Usage

| Key/Command | Action |
| ----------- | ------ |
| `Up Arrow` | Instant project-specific history |
| `Ctrl + P` | Open the fuzzy-search history palette (requires `fzf`) |
| `termim query` | Direct CLI access to project history |
| `termim suggest` | Intelligence-based command suggestions |
| `termim init` | Manually register a project (Zero-Pollution) |
| `termim doctor` | Diagnostic health check |

---

## 🛡️ Industrial Stability
Termim is 100% written in **Safe Rust.** All core logic is database-free and daemon-free, ensuring it is as stable as the shell itself.

## 🤝 Contributing
We welcome industry-grade contributions! Please see our [Contributing Guide](CONTRIBUTING.md) to get started.

## 📄 License
Termim is licensed under the **MIT License.** See [LICENSE](LICENSE) for more details.

---

<p align="center">
  Built with ❤️ by <strong>Md Mim Akhtar</strong> (@akhtarx) <br/>
  Part of the <strong>AkhtarX Labs</strong>
</p>
