<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="200"/>
</p>

<h1 align="center">Termim</h1>

<p align="center">
  <strong>A silent, project-aware terminal history engine v1.0.1</strong>
</p>

<p align="center">
  <a href="https://github.com/akhtarx/termim/releases"><img src="https://img.shields.io/github/v/release/akhtarx/termim?style=for-the-badge&color=7C3AED" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/akhtarx/termim?style=for-the-badge&color=3B82F6" alt="License"></a>
  <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge&color=10B981" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/Rust-2021-orange.svg?style=for-the-badge&color=EA580C" alt="Rust 2021">
</p>

<p align="center">
  <a href="#-philosophy">Philosophy</a> •
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-join-the-laboratory">Contributing</a>
</p>

---

**Termim** is a high-performance terminal enhancement that optimizes your shell history by providing instant access to relevant commands based on your current project context. It is designed to be invisible, fast, and 100% stable.

## 🏁 Philosophy

We believe that a developer's history is their most valuable asset. Termim treats it with the respect it deserves:

- **Silent Performance**: Termim upgrades your shell's native history buffer in real-time, delivering **0ms response times.** ⚡
- **Zero-Pollution**: We never touch your project folders. No `.termim` markers or `.history` files—your source code stays pristine. 🧼
- **Zero-Daemon**: No background processes, no databases, no maintenance. Just pure Rust efficiency. 🛡️
- **Universal Strategy**: Identical, stateful navigation across PowerShell, Bash, Zsh, and Fish.

## 🏁 Support Matrix

| Shell | Environment | Status |
| ----- | ----------- | ------ |
| **PowerShell** | Windows (Terminal/VSCode) | **Stable** ✅ |
| **Git Bash** | Windows (MinTTY) | **Stable** ✅ |
| **Zsh** | Unix / macOS / WSL / MSYS2 | **Experimental (Beta)** 🧪 |
| **Fish** | Unix / macOS / WSL / MSYS2 | **Experimental (Beta)** 🧪 |
| **Bash** | Linux / macOS | **Experimental (Beta)** 🧪 |

> [!NOTE]
> While we have achieved 'Native-Mastery' in our local laboratory (Windows/MSYS2), we are looking for brave developers to help us test and refine the Zsh and Fish integrations on native Linux and macOS systems. Your feedback helps us reach absolute universal stability! 🤝🛡️

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
| `termim stats` | Global usage statistics |
| `termim doctor` | Health check & diagnostics |

---

## 🛡️ Industrial Stability
Termim is 100% written in **Safe Rust.** All core logic is database-free and daemon-free, ensuring it is as stable as the shell itself.

## 🤝 Join the Laboratory
We believe that the best tools are built in the open. We invite you to test, report bugs, and contribute to the Termim ecosystem. Whether you are a shell-wizard or just starting out, your perspective is valuable to us.

Please see our [Contributing Guide](CONTRIBUTING.md) to get started! 🤝🛡️

## 📄 License
Termim is licensed under the **MIT License.** See [LICENSE](LICENSE) for more details.

---

<p align="center">
  Built with ❤️ by <strong>Md Mim Akhtar</strong> (@akhtarx) <br/>
  Part of the <strong>AkhtarX Labs</strong>
</p>
