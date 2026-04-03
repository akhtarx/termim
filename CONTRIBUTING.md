# Contributing to Termim

Thank you for your interest in contributing to **Termim!** Contributions from the community help make this project more robust and useful for everyone.

---

## 🚦 Code of Conduct

By participating in this project, you agree to maintain a professional, inclusive, and welcoming environment for all contributors. 

---

## 🧠 Technical Standards & Performance

Termim is built on the principle of **High-Performance Efficiency.** Every contribution should adhere to these core technical standards:

1. **The Performance Moat**: Core logic should avoid heavy dependencies (like `regex` or `once_cell`) that incur a startup tax. We aim for sub-20ms total execution time.
2. **Concurrency Safety**: All file-write operations must use **Universal Advisory Locking (`fd-lock`)** and atomic swap logic to ensure data integrity across parallel sessions.
3. **Contextual Isolation**: Project detection must strictly follow the established markers to ensure accurate ecosystem isolation (Rust, Node, PHP, etc).
4. **Privacy-First Sanitization**: Credentials and secrets must be scrubbed using the established manual sieve *before* they are logged to disk.

## 🛠️ How to Contribute

### 1. Pull Requests
- **Code Quality**: We use Rust for the core logic. Please run `cargo fmt` and `cargo clippy` before submitting your PR.
- **Performance Benchmarking**: Ensure that your changes do not significantly increase binary startup or execution latency.
- **Locking Integrity**: Any new history or stat tracking must respect the `fd-lock` advisory standard.

---

## ⚖️ License

By contributing to Termim, you agree that your contributions will be licensed under the project's **MIT License.** 

**Thank you for helping build a smarter, indestructible terminal experience!** 🚀
