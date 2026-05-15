# Termim: The Evolution of Directory-Aware Terminal History

A few weeks ago, we introduced **Termim**—a tool designed to solve "Environment Bleeding" by isolating your shell history per working directory. Since then, we’ve been hard at work professionalizing the core engine and refining the experience based on real-world engineering feedback.

Today, we’re moving Termim from a "neat utility" to a **production-grade context engine.**

---

### 📂 From "Project-Aware" to "Directory & Context-Aware"

We’ve shifted our positioning to be more precise. Termim doesn't just care about project roots; it understands the specific **directory context** you are in right now. Whether you are in a monorepo, a deeply nested backend folder, or a temporary scratch space, Termim keeps your history isolated and relevant.

### 🚀 What’s New in the v1.x Core

We’ve overhauled the infrastructure to ensure Termim is as reliable as the shell itself.

#### 1. Production-Grade Installers
We’ve rewritten our installers for Unix (Bash/Zsh/Fish) and Windows (PowerShell) to be **binary-first** and **idempotent**. 
- **No more forced builds**: The installer now fetches the correct Rust binary for your architecture automatically.
- **Security**: Every download is now verified against **SHA256 checksums** generated during our official release builds.
- **Instant Activation**: On Windows, Termim is ready to use the second the installer finishes—no terminal restart required.

#### 2. The "Privacy Sieve" (In-Memory Redaction)
Security is no longer an afterthought. Termim now includes a character-based scrubbing engine that redacts sensitive data (AWS keys, passwords, JWTs) **in-memory** before they ever hit your disk. Your history stays yours, and it stays clean.

#### 3. Low-Latency, Zero-Daemon Architecture
Termim remains a **zero-daemon** tool. There are no background services sucking up RAM. Our core logic is written in Rust and has been optimized for low-latency execution, ensuring your terminal feels as snappy as it did on day one.

#### 4. Symmetrical Shell Parity
We’ve achieved 1:1 parity across **Bash, Zsh, Fish, and PowerShell**. Whether you’re on macOS, Linux, or Windows, the behavior is identical:
- **Up Arrow**: Strictly your directory history (The Past).
- **Down Arrow**: Intelligent behavioral predictions (The Future).

---

### 🏁 Quick Start (Try the New Installer)

If you haven't tried Termim yet, or want to upgrade to the latest production-grade version:

**Unix/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iex (iwr -useb https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.ps1)
```

### 📖 Moving Toward Transparency

We’ve also released a detailed **[ARCHITECTURE.md](https://github.com/akhtarx/termim/blob/main/ARCHITECTURE.md)** for those who want to see the "how" (Markov models, atomic locking, and state machines). 

Termim is built by engineers, for engineers. We’re focused on making the terminal a more focused, high-signal environment.

**Check it out on GitHub:** [akhtarx/termim](https://github.com/akhtarx/termim)

*Built by Md Mim Akhtar @ AkhtarX Labs*
