# 🚀 Termim v1.0.1: The Navigation & Precision Evolution

Termim has evolved from a project-aware history filter into a seamless **Context-Switching Layer** for your terminal. This release hardens the core architecture and introduces the "Frictionless Escape" mechanism.

---

## ✨ What's New?

### 🌊 Frictionless History Escape
You are no longer "trapped" in your project history. When you reach the end of your project-specific commands, Termim seamlessly transitions back into your **global shell history**. One single continuous flow, zero friction.

### 🧬 Recursive Marker Discovery
We have replaced "Heuristic Guessing" with **Deterministic Discovery**. Termim now performs a recursive upward walk to identify project roots using explicit markers (`.git`, `package.json`, `Cargo.toml`, etc.), ensuring 100% reliable context identification.

### 🛠️ Built-in Diagnostics (`termim doctor`)
A new health-check utility to verify your installation, shell hooks, and registry integrity. Run `termim doctor` to ensure your productivity environment is healthy.

---

## 🛠️ Refinement Core
- **Unified Shell Symmetry**: Identical index navigation logic across PowerShell, Zsh, Bash, and Fish.
- **Zero-Daemon / Zero-DB**: Maintained the industry's cleanest architecture with sub-millisecond execution times.
- **Enhanced Redaction**: Improved security patterns for masking credentials and secrets before they hit the disk.

---

## 🏁 How to Install / Update

### Windows (PowerShell)
```powershell
git clone https://github.com/akhtarx/termim.git; cd termim; .\installer\install.ps1
```

### macOS & Linux (Zsh, Bash, Fish)
```bash
git clone https://github.com/akhtarx/termim.git && cd termim && bash installer/install.sh
```

---
**Built with ❤️ by Md Mim Akhtar | Part of the AkhtarX Labs.**
