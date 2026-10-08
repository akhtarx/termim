use std::path::PathBuf;

pub fn termim_home_dir() -> PathBuf {
    if let Some(path) = std::env::var_os("TERMIM_HOME") {
        PathBuf::from(path)
    } else {
        dirs::home_dir().unwrap_or_default().join(".termim")
    }
}
