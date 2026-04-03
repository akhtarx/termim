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

## 🐚 Shell Hook Mechanics
Termim intercepts shell events using the most "native" hooks available to ensure long-term stability.

### 1. PowerShell (Windows)
Termim uses the `PSReadLine` module to register custom key handlers.
- **Asynchronous Logging**: Uses **PowerShell Runspaces** to offload command logging to a background thread. This ensures that the Enter key is never "blocked" by disk I/O.
- **Native Fallback**: If a project is not detected, Termim immediately yields to the native `PreviousHistory` handler.

### 2. Zsh (macOS / Linux)
Uses the **ZLE (Zsh Line Editor)** widget system. 
- **Widget Wrapping**: Termim wraps the standard `up-line-or-history` widget.
- **Original Widget Access**: Uses the `.widget` syntax (e.g., `.up-line-or-history`) to bypass recursive overrides and provide a seamless "Escape Hatch" to global history.

### 3. Bash (Git Bash / Linux)
Uses the `bind -x` mechanism to execute shell functions on specific escape sequences.
- **Prompt Command**: Leverages `PROMPT_COMMAND` to capture the previous command from the `fc` (fix command) history accurately after execution.

### 4. Fish (macOS / Linux)
Uses the native Fish `bind` system and `commandline` functions to manipulate the buffer.

---

## 🛡️ Security: Redaction Engine
Termim includes a built-in **Redaction Engine** that sanitizes history *before* it is committed to disk. 

- **Pattern Matching**: Uses high-performance regex to identify sensitive patterns.
- **Environment Variables**: Automatically redacts values for common secret keys (e.g., `API_KEY=***`, `SECRET_TOKEN=***`).
- **URL Credentials**: Identifies and masks credentials in protocol URLs (e.g., `https://user:***@hostname`).

---

## 🔄 Concurrency & Reliability
Because Termim is a "Zero-Daemon" tool, it relies on atomic filesystem operations to handle multiple terminal windows:

1. **Atomic Appends**: Uses the `O_APPEND` flag for logging, which is atomic on most modern local filesystems.
2. **Stateless Querying**: Each `UpArrow` press triggers a fresh read of the project-specific history file, ensuring that commands run in one window are instantly available in another.
3. **No Lock-Files**: By avoiding complex databases, Termim eliminates the risk of "Locked Database" errors during concurrent usage.

---
**Termim: Systems thinking applied to the terminal.**
