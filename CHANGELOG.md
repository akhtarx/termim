# Changelog

All notable changes to the **Termim** project will be documented in this file.

---

## [1.1.4] - 2026-06-03
### ⚡ Performance & Hardening
- **Windows File Locking Parity**: Updated `append_to_file_locked` and `prune_log` to safely release file handle locks on Windows before renaming temporary files, eliminating `Access is denied` errors.
- **Robust Test Coverage**: Added comprehensive unit tests for project ecosystem profiling, suggestion filtering, log pruning, and concurrent locking.
- **Accurate Branding**: Cleaned up outdated Markov modeling references in all website resources, docs, scripts, and logs in favor of transparent weighted transition terminology.

## [1.1.3] - 2026-05-16
### ✨ Added
- **Global History Search Palette**: The `Ctrl+P` search palette is now **Layered (Local > Global)**. It prioritizes the current project but falls back to global history, solving the "intent mismatch" when you need commands from other projects.
- **Improved Escape Path**: Added a clean, redacted Global History fallback to the `query` command, providing a smoother transition before the shell hits native history.
- **Industrial Support Matrix**: Updated `README.md` with a professional shell support matrix and industrial-grade project badges.

### 🛠️ Hardening
- **Smart Deduplication**: Improved the query engine to ensure zero duplicates when merging local and global history contexts.

## [1.1.2] - 2026-05-16
### 🐛 Bug Fixes
- **Intelligent Shell Detection**: The installer now uses the `$SHELL` environment variable for more accurate sourcing instructions (fixing the Mac/Zsh `~/.bashrc` mismatch).
- **Installer Checksum Fix**: Updated the installation logic to verify binaries using their original release names before renaming, ensuring robust `sha256sum -c` verification.
- **fzf Prompt Recovery**: Added TTY redirection (`< /dev/tty`) to the `read` command in the installer, preventing the `fzf` prompt from being skipped when piped from `curl`.

## [1.1.1] - 2026-05-10
### 🔒 Security
- **Expanded Redaction Engine**: Added patterns for `export VAR=VALUE` / `set VAR=VALUE` shell assignments, `Bearer`/`Basic`/`Authorization` header values, well-known secret prefixes (`ghp_`, `gho_`, `github_pat_`, `sk-`, `AKIA…`, `xox…`, JWT `eyJ…`), and long base64 blobs (≥20 chars after `=`).

### ⚡ Performance & Reliability
- **Atomic Writes Everywhere**: Replaced in-place seek/truncate in `append_to_file_locked` and `prune_log` with `tempfile` + atomic rename. Eliminates partial-write data loss under concurrent terminal sessions.
- **Memory-Efficient History Reads**: Replaced full-file `read_to_string` with a circular-buffer tail reader (`QUERY_TAIL_LINES = 500`). History queries and suggestions now use O(N) bounded RAM instead of loading entire files.
- **TOCTOU-Safe Prune**: File size and line-count checks are now performed inside the write lock, closing the time-of-check / time-of-use race window.
- **Hard File-Size Cap**: Added a 512 KB ceiling (`MAX_FILE_SIZE_BYTES`) enforced during every prune cycle. Prevents unbounded growth and potential DoS from noisy histories.
- **Per-Project Prune on Log**: History files are now pruned after every write (not just global stats), keeping each project file bounded to `MAX_HISTORY_LINES = 1000`.
- **Surfaced Write Errors**: `append_to_file_locked` failures now emit a `[termim] warn:` message instead of silently discarding the error.

### 🩺 Doctor Command (v1.1.1)
- Added **permissions check** (verifies write access to `~/.termim/projects/`).
- Added **file health report**: shows line count + size of `global_stats.txt` with a size-cap warning.
- Added **plugin content sanity check**: flags empty shell plugin files.
- Added **self-latency benchmark**: measures SHA-256 hash cost against the `<5ms` target.
- Added **pass/fail summary** line at the end of the diagnostic output.

## [1.1.0] - 2026-05-02
### Added
- **PowerShell Memory Leak Fixes**: Auto-disposal of .NET runspaces upon shell exit to prevent long-term memory leaks.
- **Race-Free Advisory Locking**: Secured the file metadata checks inside the write lock to completely prevent concurrency race conditions.
- **Deduplicated Modules**: Extracted duplicate functions into a canonical, unified helper module.
- **Optimized Shell Navigation**: Eliminates git subprocess forking on arrow presses via prompt-level branch caching.

## [1.0.9] - 2026-04-10
### Added
- **Multi-Dimensional Context Engine**: Universal failure-state awareness and Git branch isolation.
- **Smart Weighting**: Prioritizes recovery commands after a failure and identifies branch-specific behavioral patterns.
- **Enhanced Shell Integration**: Automatic metadata passing (Branch & Exit Code) for Bash, Zsh, Fish, and PowerShell.

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
