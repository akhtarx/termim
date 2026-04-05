use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};

pub fn normalize_path_internal(path: &Path) -> String {
    let mut s = path.to_string_lossy().to_string();
    if s.starts_with(r"\\?\") {
        s = s[4..].to_string();
    }
    s.replace('\\', "/").to_lowercase()
}

pub fn detect_project_root(current_dir: &Path) -> PathBuf {
    // 1. Check Global Registry (~/.termim/registry.txt) for explicit grouping
    if let Some(mut registry_path) = dirs::home_dir() {
        registry_path.push(".termim/registry.txt");
        if let Ok(content) = std::fs::read_to_string(&registry_path) {
            let current_norm = normalize_path_internal(current_dir);
            for line in content.lines() {
                if !line.trim().is_empty() {
                    let registered_raw = Path::new(line);
                    let registered_norm = normalize_path_internal(registered_raw);
                    
                    // [v1.1.8] Direct string-based component matching for absolute symmetry
                    if current_norm == registered_norm || current_norm.starts_with(&format!("{}/", registered_norm)) {
                         return registered_raw.to_path_buf();
                    }
                }
            }
        }
    }

    // 2. Default: Each directory is its own project (Isolated by default)
    current_dir.to_path_buf()
}

pub fn hash_project_path(path: &Path) -> String {
    let mut hasher = Sha256::new();
    // [v1.1.8] Normalize BEFORE hashing to guarantee a single file identity
    let path_str = normalize_path_internal(path);
    hasher.update(path_str.as_bytes());
    format!("{:x}", hasher.finalize())
}
