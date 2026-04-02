<p align="center">
  <img src="assets/logo.png" alt="Termim Logo" width="200"/>
</p>

<h1 align="center">Termim</h1>

<p align="center">
  <strong>Project-aware terminal history and contextual intelligence</strong>
</p>

<p align="center">
  <a href="https://github.com/akhtarx/termim/releases"><img src="https://img.shields.io/github/v/release/akhtarx/termim?style=for-the-badge&color=7C3AED" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/akhtarx/termim?style=for-the-badge&color=3B82F6" alt="License"></a>
  <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge&color=10B981" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/Rust-2021-orange.svg?style=for-the-badge&color=EA580C" alt="Rust 2021">
</p>

<p align="center">
  <a href="#-about-termim">About</a> •
  <a href="#-key-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-shell-support">Shell Support</a> •
  <a href="#-how-it-works">How it Works</a> •
  <a href="#-usage">Usage</a>
</p>

---

## 🏁 About Termim

Standard shell history is a single, massive list of every command you've ever run. **Termim** changes that by making your history **project-aware.** 

It automatically detects the root of your current project and provides a filtered, contextually relevant history. Whether you're switching between a Rust backend, a React frontend, or a Python script, Termim ensures that `Up Arrow` always gives you the command you actually need for *that* specific project.

### Why use Termim?
- **Zero-Daemon Architecture**: No background processes or services running. It integrates directly into your shell's hooks for maximum performance.
- **Zero-Database**: History is stored in transparent, plain-text files. No complex database management or corruption risks.
- **Privacy First**: Built-in regex-based redaction automatically filters sensitive information like API keys, tokens, and passwords before they hit the disk.
- **No Project Pollution**: Termim doesn't litter your project folders with `.history` or `.termim` files. All data is managed centrally in your user profile.

---

## 🚀 Key Features

- **Project Isolation**: History is automatically segregated by project root. `Up Arrow` provides context-specific commands for the current project.
- **Fuzzy Search Palette**: Press `Ctrl+P` (requires `fzf`) for a searchable, interactive history list.
- **Native Navigation**: Use your standard `Up` and `Down` arrows to navigate project history. For maximum focus, navigation is **Hard-Locked** to the current project and does not "bleed" into your global shell history.
- **Zero Latency**: Written in Rust for near-instant execution and 0ms impact on your shell's responsiveness.
- **Bundled fzf**: The installer automatically sets up `fzf` if missing, providing a zero-dependency setup for the history palette.

---

## 📦 Installation

Termim supports all major shell environments. Choose the installation method for your primary shell.

### 💻 Windows (PowerShell & Git Bash)
1. Open **PowerShell** and clone the repository:
   ```powershell
   git clone https://github.com/akhtarx/termim.git
   cd termim
   ```
2. Run the universal Windows installer:
   ```powershell
   .\installer\install.ps1
   ```
> [!TIP]
> This installer automatically configures both **PowerShell** and **Git Bash** in a single pass.

### 🍎 macOS & 🐧 Linux (Zsh, Bash, Fish)
1. Open your terminal and clone the repository:
   ```bash
   git clone https://github.com/akhtarx/termim.git
   cd termim
   ```
2. Run the universal Unix installer:
   ```bash
   bash installer/install.sh
   ```
> [!TIP]
> This script detects your shell (whether it's **Zsh**, **Bash**, or **Fish**) and performs the integration automatically.

---

## 🏁 Shell Support Matrix

Termim features are tested across multiple environments. The matrix below shows the current stability for navigation and interactive features.

| Shell | Environment | Up/Down Arrow | Ctrl+P (Palette) | Status |
| :--- | :--- | :--- | :--- | :--- |
| **PowerShell** | Windows | Stable ✅ | Stable ✅ | Production |
| **Bash** | Git Bash / Linux | Stable ✅ | Stable ✅ | Production |
| **Zsh** | macOS / Unix | Stable ✅ | **Untested** 🧪 | Beta |
| **Fish** | macOS / Unix | Stable ✅ | **Untested** 🧪 | Beta |

*Untested features are fully implemented but require community validation on native macOS/Linux environments.*

---

## 🧠 How it Works

Termim uses a "Shadow Registry" system to manage project history without polluting your source code.

1. **Detection**: When you run a command, Termim's shell hook identifies the current directory.
2. **Registry Check**: It checks `~/.termim/registry.txt` to see if the directory (or any of its parents) is a registered project.
3. **Logging**: If a project is found, the command is sanitized and appended to the project's specific history file in `~/.termim/history/`. 
4. **Recall**: When you press `Up Arrow`, Termim queries the local project history first. This ensures you only see relevant commands while working within a project.

---

## 📖 Usage

### Navigation & Keybindings
| Key | Action |
| :--- | :--- |
| **Up Arrow** | Cycle through project-specific history. |
| **Down Arrow** | Cycle forward or restore the original input. |
| **Ctrl + P** | Open the interactive fuzzy-search history palette. |

### CLI Commands
| Command | Description |
| :--- | :--- |
| `termim init` | Register the current directory as a project root. |
| `termim query` | List history and commands for the current project. |
| `termim suggest` | Get context-aware command suggestions for the project. |
| `termim stats` | View global terminal usage statistics and trends. |
| `termim doctor` | Run a diagnostic health check of your installation. |
| `termim --help` | View all available CLI options. |

---

## 🛡️ Security & Privacy

Termim includes a **Redaction Engine** that sanitizes your history before it is written to disk. This ensures that sensitive credentials are never stored in plain text.

The engine currently targets:
- **Environment Variables**: Patterns like `KEY=value`, `TOKEN=value`, or `SECRET=value` (case-insensitive) are automatically redacted.
- **URL Credentials**: Passwords in URLs (e.g., `https://user:password@host`) are identified and hidden.

Your history data remains local, transparent, and entirely under your control.

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) to get started.

## 📄 License

Termim is licensed under the **MIT License.** See [LICENSE](LICENSE) for more details.

---

<p align="center">
  Built with ❤️ by <strong>Md Mim Akhtar</strong><br/>
  Assisted by <strong>AI Tools</strong><br/>
  Part of the <strong>AkhtarX Labs</strong>
</p>
