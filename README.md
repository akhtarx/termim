<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="200"/>
</p>

<h1 align="center">Termim</h1>

<p align="center">
  <strong>Project-aware terminal history + command intelligence v1.0.0</strong>
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
- **Zero-Pollution Philosophy**: No hidden `.termim` markers or `.history` files are ever created in your folders. 🧼
- **Zero-Daemon Architecture**: No background processes, no databases, no maintenance. Just pure Rust performance. 🛡️
- **Context-Aware IQ**: Automatically identifies 34+ stacks (Node, Rust, Go, Python, Docker, etc.) and suggests relevant commands without configuration.

---

## 🚀 Features

- **Fuzzy Search Palette**: Press `Ctrl+P` (requires `fzf`) to search your project history in a premium popup.
- **Project Isolation**: Your history is segregated by project-root. No more searching through unrelated commands.
- **Global Registry**: `termim init` registers projects globally, keeping your source code 100% pristine.
- **Cross-Shell Stability**: Deep, battle-tested integration for **PowerShell**, **Zsh**, **Bash**, and **Fish**.

---

## 📦 Installation

### Windows (PowerShell)
```powershell
git clone https://github.com/akhtarx/termim.git
cd termim
.\installer\install.ps1
```

### Unix / macOS (Zsh/Bash/Fish)
```bash
git clone https://github.com/akhtarx/termim.git
cd termim
bash installer/install.sh
```

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
