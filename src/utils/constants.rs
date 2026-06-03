/// Maximum per-project history lines kept (pruned atomically when exceeded)
pub const MAX_HISTORY_LINES: usize = 1000;
/// Maximum per-project transition lines kept (pruned atomically when exceeded)
pub const MAX_TRANSITION_LINES: usize = 1000;
/// Maximum global stats lines kept
pub const MAX_GLOBAL_STATS_LINES: usize = 5000;
/// Hard file-size cap before a forced prune is triggered (512 KB)
pub const MAX_FILE_SIZE_BYTES: u64 = 512 * 1024;
/// Maximum lines loaded into memory for reverse-query reads
pub const QUERY_TAIL_LINES: usize = 500;
/// Project history subdirectory name
pub const PROJECTS_DIR: &str = "projects";
