# Termim Architecture

Termim is built on the principle of **Reliable Continuity.** Every architectural decision—from binary startup to file pruning—is optimized for low-latency execution and strong data integrity.

## 1. Technical Core

Termim converts standard, chronological shell history into a **behavioral contextual memory layer**. It is designed for engineers seeking project-local isolation with negligible overhead.

### Multi-Dimensional Context
Termim distinguishes between Git branches and prioritizes recovery commands after failures. It uses directory normalization to ensure that `/Users/path` and `~/path` are recognized as the same context.

### Symmetrical Navigation
A deterministic state machine providing 1:1 parity between PowerShell, Bash, Zsh, and Fish. All four shell hooks share a synchronized logic for managing history indices.

### Static Dispatch
A low-latency dispatch registry providing follow-up suggestions without unnecessary disk I/O. It uses a predefined map of "stack-defining" commands (e.g., `npm install` -> `npm run dev`).

### The Zero-Daemon Tradeoff
Termim explicitly avoids a persistent background daemon architecture. Spawning a new Rust process per command incurs an OS penalty (~10-20ms) that a daemon could avoid by amortizing startup costs via IPC. However, because humans type commands at a frequency of seconds, this 20ms penalty is imperceptible. In exchange for this marginal CPU penalty, Termim completely eliminates persistent background memory footprints, IPC socket complexities, and zombie process lifecycles. It is a conscious tradeoff favoring absolute state simplicity and zero idle memory over raw micro-latency.

## 2. Robust Operations

### Optimized RegEx
Termim uses precise regular expressions for robust credential redaction. Patterns are compiled once via `std::sync::OnceLock` and applied to every command before it touches the disk.

### State Initialization
Uses fast and reliable lazy initialization patterns to ensure efficient, safe startup. This minimizes the binary's impact on shell startup time.

## 3. Concurrency & Integrity

### Universal Advisory Locking (`fd-lock`)
Every file-write operation is protected by cross-platform advisory locks. This prevents race conditions between multiple parallel terminal sessions.

### Atomic In-Place Modifications
When pruning or updating history files, Termim writes modifications in-place while continuously holding the lock. This ensures that history files are never corrupted or subjected to lost updates across concurrent sessions.

## 4. Adaptive Intelligence (Weighted Command Transitions)

Termim uses a **Unified Weighted Ranking Engine** to prioritize history and predictions:

- **Behavioral Transitions**: High-coefficient weighting for literal next-step habits based on weighted transition prediction.
- **Ecosystem Defaults**: Static dispatch for stack-defining commands.
- **Directory Context**: Frequency-based ranking within the local directory boundary.

## 5. Privacy Sieve

A character-based redaction engine masks:
- Credentials & Tokens (Passwords, API keys)
- Multi-Token Secrets (Bearer tokens, Authorization headers)
- URL Credentials (https://user:pass@host)
