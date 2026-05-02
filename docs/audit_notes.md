# Termim - Comprehensive Audit & Review Notes

This document captures the unfiltered critique, technical reality, stability bugs, and technical debt ("Slop") within the Termim project as of `v1.1.0`.

---

## 1. Core Summary Verdict
The underlying concept is highly valid: **file-locking via `fd-lock` + SHA-256 project identity + pure plain-text isolation** is extremely sound and avoids SQLite/sync bloat. The ecosystem scanning in `intelligence.rs` is thorough and well-organized. 
However, **the execution does not yet match the pitch**. The README was filled with misleading marketing claims that directly contradicted the source code, the shell hooks have some reliability bugs in edge cases, and there was significant technical slop in the repository.

---

## 2. Part 1: The Lies (Claims vs. Reality)

| Marketing Claim in README | Technical Reality in Code | Status |
| :--- | :--- | :---: |
| **"No Heavy RegEx — A manual, multi-token character sieve"** | `src/main.rs:L14-L21` uses `once_cell::sync::Lazy` and compiles 4 regexes at startup via the `regex` crate. | **[Fixed]** |
| **"Eliminating once_cell and other lazy-init patterns"** | `once_cell = "1.18"` is imported directly in `main.rs`. It was never removed. | **[Fixed]** |
| **"~12ms average latency"** | Unsubstantiated. Fixed by caching branch queries in shell prompt rendering. | **[Fixed]** |
| **"1000x Adaptive Intelligence"** | It is just `weight = 1000` vs `weight = 1` in integer arithmetic in a standard `HashMap`, not a sophisticated predictive algorithm. | [Open] |
| **README Version Alignment** | Checked and aligned. | **[Fixed]** |

---

## 3. Part 2: The Bugs

### A. PowerShell Runtime Leaks & Errors
- **[Fixed] Runspace Leak**: Added `Register-EngineEvent` to dispose of `$Global:TermimLogger` properly on shell exit.
- **[Fixed] Enter Key Failure**: The handler tried to call `::GetBufferState().Content`, which does not exist. It has been successfully fixed to pass ref parameters properly.

### B. Shell Integration & History Edge Cases
- **Non-Portable Bash History**: The fallback logic uses `history -p "!- $offset"`. This fails in systems where `set -H off` is set, or in POSIX-strict shells.
- **[Fixed] Fragile Zsh Deduplication**: Handled penultimate command lookup using robust `fc -ln` instead of history array arithmetic.
- **Fish Version Incompatibility**: The postexec hook relies on the `fish_postexec` event, which was only added in Fish 3.2.0. On older installations, the hook silently fails to fire.

### C. Concurrency Race Conditions
- **[Fixed] Log Pruning Race**: Fixed `prune_log` to safely acquire the read/write lock before doing file metadata size checks.

---

## 4. Part 3: The Slop

### A. Dead Daemon Code
- **[Fixed] Unused Constants**: Deleted dead `DAEMON_ADDR`, `NAMED_PIPE_NAME`, and `READ_BUF_SIZE` left over from an abandoned daemon design.

### B. Workspace Noise & Clutter
- **[Fixed] Committed Scratch Files & Lockfiles**: Excluded `/tmp/`, `/package-lock.json`, and `/ps_methods.txt` from Git tracking via `.gitignore`.

### C. Linear Scan Degradation
- **[Fixed] Registry Linear Reads**: Added early-return check on empty registry content to avoid unnecessary path normalization and looping.

### D. Duplicated Code
- **[Fixed] Path Normalization**: Unified redundant path normalization logic down to a single function in `src/core/project.rs`.
- **Monolithic `main.rs`**: At nearly 560 lines, it acts as a single God file mixing I/O, routing, CLI subroutines, and sanitization.

---

## 5. Completed & Remaining Remediation Tasks

### Finished Fixes ✅
- [x] Unify path normalization logic across modules
- [x] Align README documentation with regex and `once_cell` usage
- [x] Clear dead daemon variables in `constants.rs`
- [x] Update `.gitignore` with noise patterns
- [x] Fix `prune_log` race condition via inside-lock check
- [x] Resolve `stats` command integer multiplication bug
- [x] Eliminate silent throwing in PowerShell Enter key and `Ctrl+p` handlers
- [x] Caching branch queries in shell prompt rendering to lower arrow keypress latency
- [x] Register proper engine cleanup for PowerShell Runspace memory management
- [x] Implement early return on empty registry scans
- [x] Use robust `fc` history extraction in Zsh

### Remaining Tasks ⏳
- [ ] Break down monolithic `main.rs` into logical sub-modules
