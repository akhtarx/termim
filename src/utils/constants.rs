/// Daemon TCP address (host:port)
pub const DAEMON_ADDR: &str = "127.0.0.1:28345";
/// Daemon Named Pipe for Windows (native IPC)
pub const NAMED_PIPE_NAME: &str = r"\\.\pipe\termimd";
/// Maximum per-project commands kept in DB/file (pruned when exceeded)
pub const MAX_COMMANDS_PER_PROJECT: i64 = 1000;
/// Read buffer size for TCP messages (128 KB)
pub const READ_BUF_SIZE: usize = 131072;
/// Project history subdirectory name
pub const PROJECTS_DIR: &str = "projects";

