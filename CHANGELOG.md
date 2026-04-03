# Changelog

All notable changes to the **Termim** project will be documented in this file.

---

## [1.0.3] - 2026-04-03
### ✨ Added
- **Weighted Behavioral Ranking**: 1000x multiplier for Markov-based command transitions.
- **Ecosystem Advice Priority**: 50x multiplier for stack-defining commands (e.g., npm, composer).
- **Resilient Project Detection**: Improved fallback logic for Node, PHP, and Go projects with minimal configuration files.
- **Version Synchronization**: Unified version alignment (v1.0.3) across all interfaces.

## [1.0.2] - 2026-04-03
### 🛠️ Hardening
- **Performance Optimization**: Removed heavy dependencies to achieve **15ms average latency**.
- **Advisory File Locking**: Integrated **`fd-lock`** for atomic file safety across parallel terminal sessions.
- **Ecosystem Isolation**: Boundary detection for Rust, Node.js, PHP, and Go projects.
- **Privacy Sieve**: High-performance manual redactor for masking credentials and secrets.
- **Success-Only Learning**: Captures exit codes to filter out failed commands from learning models.

## [1.0.1] - 2026-04-03
### ✨ Added
- **Predictive Behavioral Ranking**: First-order Markov Chain implementation that re-ranks history based on your previous command context.
- **Frictionless History Escape**: Seamlessly transition from project-specific history to global shell history when context is exhausted.
- **Recursive Marker Discovery**: Deterministic project root identification via explicit markers (`.git`, `package.json`, `Cargo.toml`, etc.).
- **Strategic Positioning Matrix**: High-impact comparison guide against Atuin, McFly, HSTR, and native tools.
- **ARCHITECTURE.md**: Dedicated technical manifesto detailing SHA-256 isolation and shell-hook strategies.
- **Doctor Command**: Added `termim doctor` for automated installation health checks.

### 🛠️ Refined
- **Universal Version Synchronization**: Unified versioning (v1.0.1) across Cargo.toml, CLI metadata, installers, and shell integrations.
- **Shell Logic Consolidation**: Removed redundant PowerShell registry parsing; now 100% delegated to the high-performance Rust core.

---

## [1.0.0] - 2026-03-31
### 🚀 Initial Release
- **Pure CLI Architecture**: The industry-first 100% Zero-Daemon, Zero-Database history tool.
- **Contextual Isolation**: Project boundaries detected via marker-rules; history segregated via SHA-256 path hashing.
- **Registry System**: A "Shadow Registry" managed in `~/.termim/` for zero project pollution.
- **Redaction Engine**: Built-in security layer to mask secrets and credentials before they hit the disk.
- **Native Support**: First-class handlers for PowerShell, Zsh, Bash, and Fish.

---
<p align="center">
  <em>Termim: Systems thinking applied to the terminal.</em>
</p>
