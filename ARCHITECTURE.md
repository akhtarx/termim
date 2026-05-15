# Termim Architecture

Termim is built on the principle of **Reliable Continuity.** Every architectural decision—from binary startup to file pruning—is optimized for low-latency execution and 100% data integrity.

## 1. Technical Core

Termim converts standard, chronological shell history into a **behavioral contextual memory layer**. It is designed for engineers seeking project-local isolation with negligible overhead.

### Multi-Dimensional Context
Termim distinguishes between Git branches and prioritizes recovery commands after failures. It uses directory normalization to ensure that `/Users/path` and `~/path` are recognized as the same context.

### Symmetrical Navigation
A deterministic state machine providing 1:1 parity between PowerShell, Bash, Zsh, and Fish. All four shell hooks share a synchronized logic for managing history indices.

### Static Dispatch
A zero-latency dispatch registry providing follow-up suggestions without unnecessary disk I/O. It uses a predefined map of "stack-defining" commands (e.g., `npm install` -> `npm run dev`).

## 2. Robust Operations

### Optimized RegEx
Termim uses precise regular expressions for robust credential redaction. Patterns are compiled once via `once_cell` and applied to every command before it touches the disk.

### State Initialization
Uses fast and reliable lazy initialization patterns to ensure efficient, safe startup. This minimizes the binary's impact on shell startup time.

## 3. Concurrency & Integrity

### Universal Advisory Locking (`fd-lock`)
Every file-write operation is protected by cross-platform advisory locks. This prevents race conditions between multiple parallel terminal sessions.

### Atomic Write-Rename
When pruning or updating history files, Termim writes to a temporary sibling file and then performs an atomic rename. This ensures that history files are never corrupted, even if the process is interrupted.

## 4. Adaptive Intelligence (Markov Weighting)

Termim uses a **Unified Weighted Ranking Engine** to prioritize history and predictions:

- **Behavioral Transitions**: High-coefficient weighting for literal next-step habits based on Markov Chain analysis.
- **Ecosystem Defaults**: Static dispatch for stack-defining commands.
- **Directory Context**: Frequency-based ranking within the local directory boundary.

## 5. Privacy Sieve

A character-based redaction engine masks:
- Credentials & Tokens (Passwords, API keys)
- Multi-Token Secrets (Bearer tokens, Authorization headers)
- URL Credentials (https://user:pass@host)
