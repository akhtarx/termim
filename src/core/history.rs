use crate::utils::constants::MAX_FILE_SIZE_BYTES;
use regex::Regex;
use std::io::{BufRead, BufReader, Write};
use std::path::Path;
use std::sync::OnceLock;

static PATTERNS: OnceLock<Vec<(Regex, &'static str)>> = OnceLock::new();

fn get_patterns() -> &'static Vec<(Regex, &'static str)> {
    PATTERNS.get_or_init(|| {
        vec![
            // Flag-style: -p VALUE, --password=VALUE, --api-key VALUE …
            (Regex::new(r"(?i)(-p|--password|--api-key|--token|--secret|--pwd|--auth|--credential)[ =]?[^ ]+").unwrap(),
                "$1=[REDACTED]"),
            // Key=value assignments (env-style): PASSWORD=foo TOKEN=bar
            (Regex::new(r"(?i)\b(password|token|api[_-]?key|secret|auth|credential|private[_-]?key|access[_-]?key|client[_-]?secret)=[^\s]+").unwrap(),
                "$1=[REDACTED]"),
            // export / set VAR=VALUE (shell assignments)
            (Regex::new(r"(?i)\b(export|set)\s+(\w+)=([^\s]+)").unwrap(),
                "$1 $2=[REDACTED]"),
            // Bearer / Authorization header values
            (Regex::new(r"(?i)(bearer|basic|authorization)[ :=][^\s]+").unwrap(),
                "$1 [REDACTED]"),
            // URL credentials: https://user:pass@host
            (Regex::new(r"(?i)(://[^:]+:)[^@]+(@)").unwrap(),
                "${1}[REDACTED]${2}"),
            // Well-known secret prefixes (GitHub PATs, OpenAI, Stripe, AWS, JWT)
            (Regex::new(r"(?i)\b(ghp_|gho_|github_pat_|sk-|ey[A-Za-z0-9]{10,}|AKIA[0-9A-Z]{16}|xox[baprs]-)[A-Za-z0-9_\-]{8,}").unwrap(),
                "[REDACTED_TOKEN]"),
            // Long base64-like blobs after = (e.g. SSH keys, base64 secrets ≥ 20 chars)
            (Regex::new(r"=[A-Za-z0-9+/]{20,}={0,2}").unwrap(),
                "=[REDACTED_B64]"),
        ]
    })
}

pub fn sanitize_command(command: &str) -> String {
    let mut scrubbed = command.trim().to_string();
    if scrubbed.is_empty() {
        return scrubbed;
    }

    for (re, replacement) in get_patterns().iter() {
        scrubbed = re.replace_all(&scrubbed, *replacement).to_string();
    }

    scrubbed
}

pub fn append_to_file_locked(path: &Path, content: &str) -> std::io::Result<()> {
    let parent = path.parent().unwrap_or(Path::new("."));

    // Open (or create) the target file and hold a write lock for the duration.
    let target = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(path)?;
    let mut lock = fd_lock::RwLock::new(target);
    let guard = lock.write()?;

    // Read existing content while holding the lock.
    let reader = BufReader::new(&*guard);
    let mut lines: Vec<String> = reader.lines().map_while(Result::ok).collect();

    // Drop guard and lock to close file handles before rename (crucial for Windows)
    drop(guard);
    drop(lock);

    // Append the new line.
    lines.push(content.to_string());

    // Write to a sibling temp file then rename (atomic).
    let tmp = tempfile::NamedTempFile::new_in(parent)?;
    let mut w = std::io::BufWriter::new(tmp.as_file());
    for line in &lines {
        writeln!(w, "{}", line)?;
    }
    w.flush()?;
    drop(w);
    tmp.persist(path).map_err(|e| e.error)?;
    Ok(())
}

pub fn read_file_tail(path: &Path, limit: usize) -> std::io::Result<Vec<String>> {
    if !path.exists() {
        return Ok(Vec::new());
    }
    let f = std::fs::File::open(path)?;
    let lock = fd_lock::RwLock::new(f);
    let guard = lock.read()?;
    let reader = BufReader::new(&*guard);
    // Circular buffer
    let mut ring: std::collections::VecDeque<String> =
        std::collections::VecDeque::with_capacity(limit + 1);
    for line in reader.lines().map_while(Result::ok) {
        if !line.is_empty() {
            if ring.len() == limit {
                ring.pop_front();
            }
            ring.push_back(line);
        }
    }
    Ok(ring.into_iter().collect())
}

pub fn read_file_locked(path: &Path) -> std::io::Result<String> {
    if !path.exists() {
        return Ok(String::new());
    }
    let f = std::fs::File::open(path)?;
    let lock = fd_lock::RwLock::new(f);
    let guard = lock.read()?;
    let mut reader = BufReader::new(&*guard);
    let mut content = String::new();
    std::io::Read::read_to_string(&mut reader, &mut content)?;
    Ok(content)
}

pub fn prune_log(path: &Path, max_lines: usize) -> std::io::Result<()> {
    if !path.exists() {
        return Ok(());
    }
    let parent = path.parent().unwrap_or(Path::new("."));

    let f = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(path)?;
    let mut lock = fd_lock::RwLock::new(f);
    let guard = lock.write()?;

    // Size cap check — inside the lock.
    let needs_prune = guard
        .metadata()
        .map(|m| m.len() > MAX_FILE_SIZE_BYTES)
        .unwrap_or(false);

    let reader = BufReader::new(&*guard);
    let lines: Vec<String> = reader.lines().map_while(Result::ok).collect();

    // Skip prune if file is small enough.
    if !needs_prune && lines.len() <= max_lines {
        return Ok(());
    }

    let start_idx = lines.len().saturating_sub(max_lines);

    // Drop guard and lock to close file handles before rename (crucial for Windows)
    drop(guard);
    drop(lock);

    let tmp = tempfile::NamedTempFile::new_in(parent)?;
    let mut w = std::io::BufWriter::new(tmp.as_file());
    for line in lines.iter().skip(start_idx) {
        writeln!(w, "{}", line)?;
    }
    w.flush()?;
    drop(w);
    tmp.persist(path).map_err(|e| e.error)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_command() {
        // Redacts password flag
        assert_eq!(
            sanitize_command("mysql -p secret_pass"),
            "mysql -p=[REDACTED]"
        );
        // Redacts env var token
        assert_eq!(
            sanitize_command("token=xyz123 cargo run"),
            "token=[REDACTED] cargo run"
        );
        // Redacts authorization header (regex consumes non-whitespace including the trailing quote)
        assert_eq!(
            sanitize_command("curl -H 'Authorization: Bearer mytoken'"),
            "curl -H 'Authorization: Bearer [REDACTED]"
        );
        // No redaction for normal commands
        assert_eq!(sanitize_command("git status"), "git status");
    }

    #[test]
    fn test_append_and_read_tail() {
        let temp_dir = tempfile::tempdir().unwrap();
        let file_path = temp_dir.path().join("test_history.log");

        append_to_file_locked(&file_path, "command 1").unwrap();
        append_to_file_locked(&file_path, "command 2").unwrap();
        append_to_file_locked(&file_path, "command 3").unwrap();

        let tail = read_file_tail(&file_path, 2).unwrap();
        assert_eq!(tail.len(), 2);
        assert_eq!(tail[0], "command 2");
        assert_eq!(tail[1], "command 3");

        let full = read_file_locked(&file_path).unwrap();
        assert!(full.contains("command 1\n"));
        assert!(full.contains("command 2\n"));
        assert!(full.contains("command 3\n"));
    }

    #[test]
    fn test_prune_log() {
        let temp_dir = tempfile::tempdir().unwrap();
        let file_path = temp_dir.path().join("test_prune.log");

        for i in 1..=10 {
            append_to_file_locked(&file_path, &format!("cmd {}", i)).unwrap();
        }

        prune_log(&file_path, 5).unwrap();

        let tail = read_file_tail(&file_path, 10).unwrap();
        assert_eq!(tail.len(), 5);
        assert_eq!(tail[0], "cmd 6");
        assert_eq!(tail[4], "cmd 10");
    }
}
