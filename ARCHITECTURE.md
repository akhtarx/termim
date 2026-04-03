# Termim: Technical Architecture

This document provides a deep-dive into the design decisions, data structures, and shell-integration strategies that power Termim's context-aware history.

---

## 🏗️ Design Philosophy: "Zero-Everything"
Termim is built on the principle of **Passive Integration**. Most developer tools fail by adding too much overhead; Termim aims for the opposite.

- **Zero-Daemon**: No background processes to manage, monitor, or restart.
- **Zero-Database**: No SQLite/Postgres overhead or corruption risks.
- **Zero-Latency**: Rust-compiled binaries execute in sub-millisecond timeframes, ensuring zero impact on the shell event loop.

---

## 📁 Data Storage & Isolation

### The Shadow Registry
Termim avoids "Project Pollution" (littering `.history` or `.termim` files inside your source code directories). Instead, it maintains a **Centralized Shadow Registry** at `~/.termim/`.

- **Project Identification**: Termim uses a recursive marker scan to identify project boundaries (searching for `.git`, `package.json`, `Cargo.toml`, etc.).
- **Path Hashing**: Project roots are normalized (lowercased on Windows to prevent casing duplication) and hashed using **SHA-256**.
- **Filesystem Isolation**: History for each project is stored in a unique, plain-text file: `~/.termim/projects/{hash}.txt`. This architecture prevents history "bleeding" and allows for easy manual inspection.

---

## 🧠 Behavioral Intelligence: Markov 1000x

Termim v1.0.3 introduces a **Unified Weighted Ranking Engine.** Instead of simple frequency, it uses a first-order Markov Chain to predict your next command.

- **Command Transitions**: Every successful command execution (`exit code 0`) is logged as a transition in `~/.termim/projects/{hash}_transitions.txt`.
- **Weight Hierarchy**:
    - **Habits (1000x)**: If you just ran `git add`, Termim looks at your transition history. Commands that frequently follow `git add` are given a massive 1000x boost.
    - **Ecosystem (50x)**: Commands matching the detected stack (e.g., `npm`, `cargo`) are given a secondary 50x boost.
    - **Frequency (1x)**: Local project-specific frequency is the baseline.

---

## 🐚 Shell Hook Mechanics (Hardened)

Termim intercepts shell events using the most "native" hooks available to ensure long-term stability.

### 1. PowerShell (Windows)
- **Success-Only learning**: Captures `$lastExitCode` in the `prompt` function to ensure Termim only learns your successful habits.
- **Asynchronous Execution**: Offloads logging to background threads to prevent UI lag.

### 2. Unix Shells (Zsh, Bash, Fish)
- **Exit Status Filtering**: Uses `precmd`/`PROMPT_COMMAND` or `fish_postexec` to capture `$?` for success-filtering.

---

## 🛡️ Security: High-Performance Sieve

In v1.0.3, Termim eliminated the "Library Startup Tax" by removing heavy regex engines. 

- **Manual Character Sieve**: Uses a zero-dependency string iterator to identify and mask sensitive tokens in **<0.5ms**.
- **Multi-Token Masking**: Identifies `KEY=secret`, `TOKEN:secret`, and `https://user:***@host` patterns by scanning for separator delimiters (`=`, `:`, `@`).

---

## 🔄 Concurrency & Indestructible Locking

Termim v1.0.3 transitioned to an **Industrial-Grade Locking Standard** to handle extreme concurrency across multiple terminal parallel sessions:

1. **Universal Advisory Locking**: Uses **`fd-lock`** on all history write operations. This ensures that even if two terminal instances attempt to prune or log at the exact same microsecond, they synchronize safely without data corruption.
2. **Atomic Swap Logic**: When pruning the history log, Termim writes to a `.tmp` file and performs an **Atomic Rename** to the original target. This ensures the history file is either 100% complete or remains at its previous state—never partially written.

---
**Termim: Systems thinking applied to the terminal.**
