# Changelog

All notable changes to the **Termim** project will be documented in this file.

---

## [1.0.8] - 2026-04-09
### Added
- OS-Aware Path Normalization: Fixed critical project collision flaw on Linux (case-sensitive systems).
- High-Fidelity Uninstall: Integrated Windows Registry PATH cleanup and self-deletion logic.
- GitHub Funding: Added FUNDING.yml for community support.

### Changed
- Hot-Path Optimization: Implemented lazy-initialized regexes for sub-millisecond logging performance.
- Visual Alignment: Mathematically aligned ASCII banner for distortion-free rendering.

## [1.0.7] - 2026-04-08
### ✨ Added
- **Multi-Platform Releases**: Automated GitHub Actions to build for Windows, Linux, and macOS.
- **Smart Universal Installers**: Automatic binary fallback for users without a Rust toolchain.

## [1.0.6] - 2026-04-08
### ✨ Added
- **Manual Update Check**: Added `termim update` to safely check for latest releases on GitHub without background tracking.
- **Data Clear Command**: Added `termim clear` to allow users to reset all project history, registry, and statistics with a safety confirmation.

## [1.0.5] - 2026-04-05
### ✨ Added
- **O(1) Static Dispatch Engine (v1.6.3)**: A compiled-in suggestion registry for common developer context (Git, Cargo, NPM, etc.), achieving zero-latency suggestions via in-memory maps.
- **Symmetric Future Navigation**: Contextual prediction triggering for empty shell prompts, enabling a non-destructive "Down-Arrow" transition.

### 🛠️ Hardening
- **Deterministic Shell Parity (v1.5.3)**: Unified 1:1 navigation logic across PowerShell, Bash, Zsh, and Fish. Mathematical symmetry achieved across all pointers.
- **Identity Normalization (v1.1.8)**: String-based path normalization (Lowercase/UNC-strip) ensures deterministic context detection across Windows and POSIX environments.

## [1.0.4] - 2026-04-03
### ✨ Added
- **State-Aware Context Capture**: Precision directory and exit-status capture for PowerShell hooks.
- **Heuristic Ecosystem Analysis**: Deterministic command suggestions based on project-root file analysis.

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
