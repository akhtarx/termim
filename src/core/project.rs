use std::path::{Path, PathBuf};
use sha2::{Sha256, Digest};


pub fn detect_project_root(current_dir: &Path) -> PathBuf {
    let markers = [
        ".git",
        "package.json",
        "Cargo.toml",
        "go.mod",
        "pyproject.toml",
        "Makefile",
        "docker-compose.yml",
    ];

    let mut path = current_dir.to_path_buf();
    while let Some(parent) = path.parent() {
        for marker in &markers {
            if path.join(marker).exists() {
                return path;
            }
        }
        path = parent.to_path_buf();
    }

    // 2. Check Global Registry (~/.termim/registry.txt)
    if let Some(mut registry) = dirs::home_dir() {
        registry.push(".termim/registry.txt");
        if let Ok(content) = std::fs::read_to_string(&registry) {
            let current_dir_str = current_dir.to_string_lossy().to_string();
            for line in content.lines() {
                if current_dir_str.starts_with(line) {
                    return PathBuf::from(line);
                }
            }
        }
    }

    current_dir.to_path_buf()
}

pub fn hash_project_path(path: &Path) -> String {
    let mut hasher = Sha256::new();
    // On Windows, normalize casing to avoid duplicate history for the same project
    let path_str = if cfg!(target_os = "windows") {
        path.to_string_lossy().to_lowercase()
    } else {
        path.to_string_lossy().to_string()
    };
    hasher.update(path_str.as_bytes());
    format!("{:x}", hasher.finalize())
}
