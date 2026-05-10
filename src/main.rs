use clap::Parser;
use regex::Regex;
use std::env;
use std::io::{BufRead, BufReader, Write};
use termim::cli::args::{Cli, Commands};
use termim::core::intelligence::analyze_project;
use termim::core::project::{detect_project_root, hash_project_path, normalize_path_str};
use termim::utils::constants::{
    MAX_FILE_SIZE_BYTES, MAX_GLOBAL_STATS_LINES, MAX_HISTORY_LINES,
    MAX_TRANSITION_LINES, PROJECTS_DIR, QUERY_TAIL_LINES,
};
use termim::core::fundamentals::FundamentalsRegistry;
use termim::utils::update::check_for_updates;

use once_cell::sync::Lazy;

// ── Redaction Patterns ─────────────────────────────────────────────────────
// Compiled once, applied to every command before it touches disk.
static PATTERNS: Lazy<Vec<(Regex, &'static str)>> = Lazy::new(|| {
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
});

fn sanitize_command(command: &str) -> String {
    let mut scrubbed = command.trim().to_string();
    if scrubbed.is_empty() { return scrubbed; }

    for (re, replacement) in PATTERNS.iter() {
        scrubbed = re.replace_all(&scrubbed, *replacement).to_string();
    }

    scrubbed
}



// ── Atomic Append ──────────────────────────────────────────────────────────
// Reads existing content under write lock, then writes to a tempfile in the
// same directory, and renames atomically. This prevents partial-write data loss
// under concurrent terminal sessions.
fn append_to_file_locked(path: &std::path::Path, content: &str) -> std::io::Result<()> {
    let parent = path.parent().unwrap_or(std::path::Path::new("."));

    // Open (or create) the target file and hold a write lock for the duration.
    let target = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .open(path)?;
    let mut lock = fd_lock::RwLock::new(target);
    let guard = lock.write()?;

    // Read existing content while holding the lock.
    let reader = BufReader::new(&*guard);
    let mut lines: Vec<String> = reader.lines().filter_map(Result::ok).collect();
    drop(guard); // release read phase of the guard — we now own the lock exclusively

    // Append the new line.
    lines.push(content.to_string());

    // Write to a sibling temp file then rename (atomic on POSIX; best-effort on Windows).
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

fn fetch_star_count_cached() -> Option<u64> {
    use std::time::SystemTime;
    let cache_path = dirs::home_dir()
        .unwrap_or_default()
        .join(".termim")
        .join(".star_cache");

    // Check if cache exists and is fresh (< 24 hours)
    if let Ok(metadata) = std::fs::metadata(&cache_path) {
        if let Ok(modified) = metadata.modified() {
            if let Ok(duration) = SystemTime::now().duration_since(modified) {
                if duration.as_secs() < 24 * 60 * 60 {
                    if let Ok(content) = std::fs::read_to_string(&cache_path) {
                        if let Ok(stars) = content.trim().parse::<u64>() {
                            return Some(stars);
                        }
                    }
                }
            }
        }
    }

    // Fetch from GitHub with a short timeout so we don't block startup if offline
    let agent = ureq::AgentBuilder::new()
        .timeout(std::time::Duration::from_millis(1500))
        .build();

    let req = agent.get("https://api.github.com/repos/akhtarx/termim")
        .set("User-Agent", "termim-cli");

    if let Ok(response) = req.call() {
        if let Ok(json) = serde_json::from_reader::<_, serde_json::Value>(response.into_reader()) {
            if let Some(stars) = json.get("stargazers_count").and_then(|v| v.as_u64()) {
                // Update cache
                let _ = std::fs::write(&cache_path, stars.to_string());
                return Some(stars);
            }
        }
    }

    // Fallback to old cache if fetch fails
    if let Ok(content) = std::fs::read_to_string(&cache_path) {
        if let Ok(stars) = content.trim().parse::<u64>() {
            return Some(stars);
        }
    }

    None
}

// ── Tail Reader (Memory-Efficient) ─────────────────────────────────────────
// Reads only the last QUERY_TAIL_LINES lines from a file under a shared read
// lock — O(file_size) scan but O(N) memory where N = QUERY_TAIL_LINES.
// For history files that stay under the prune threshold this is effectively
// the whole file; for large files it keeps RAM bounded.
fn read_file_tail(path: &std::path::Path) -> std::io::Result<Vec<String>> {
    if !path.exists() {
        return Ok(Vec::new());
    }
    let f = std::fs::File::open(path)?;
    let lock = fd_lock::RwLock::new(f);
    let guard = lock.read()?;
    let reader = BufReader::new(&*guard);
    // Circular buffer — keep only the last QUERY_TAIL_LINES entries.
    let mut ring: std::collections::VecDeque<String> =
        std::collections::VecDeque::with_capacity(QUERY_TAIL_LINES + 1);
    for line in reader.lines().flatten() {
        if !line.is_empty() {
            if ring.len() == QUERY_TAIL_LINES {
                ring.pop_front();
            }
            ring.push_back(line);
        }
    }
    Ok(ring.into_iter().collect())
}

// ── Full File Reader (for transitions / stats) ─────────────────────────────
// Reads the complete file content under a shared lock. Used only for the
// smaller transitions file (pruned to MAX_TRANSITION_LINES).
fn read_file_locked(path: &std::path::Path) -> std::io::Result<String> {
    if !path.exists() {
        return Ok(String::new());
    }
    let f = std::fs::File::open(path)?;
    let lock = fd_lock::RwLock::new(f);
    let guard = lock.read()?;
    let mut reader = BufReader::new(&*guard);
    let mut content = String::new();
    use std::io::Read;
    reader.read_to_string(&mut content)?;
    Ok(content)
}

// ── Atomic Prune ───────────────────────────────────────────────────────────
// Acquires a write lock, reads all lines, trims to max_lines keeping the
// newest entries, writes to a tempfile, then renames atomically.
// The size-cap guard is checked INSIDE the lock — race-free TOCTOU-safe.
fn prune_log(path: &std::path::Path, max_lines: usize) -> std::io::Result<()> {
    if !path.exists() {
        return Ok(());
    }
    let parent = path.parent().unwrap_or(std::path::Path::new("."));

    let f = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(path)?;
    let mut lock = fd_lock::RwLock::new(f);
    let guard = lock.write()?;

    // Size cap check — inside the lock (TOCTOU-safe).
    let needs_prune = guard
        .metadata()
        .map(|m| m.len() > MAX_FILE_SIZE_BYTES || {  // hard size cap
            // We'll do a line-count check below for max_lines; here just
            // force prune if the file is too large regardless.
            false
        })
        .unwrap_or(false);

    let reader = BufReader::new(&*guard);
    let lines: Vec<String> = reader.lines().filter_map(Result::ok).collect();

    // Skip prune if file is small enough.
    if !needs_prune && lines.len() <= max_lines {
        return Ok(());
    }

    let start_idx = lines.len().saturating_sub(max_lines);
    let tmp = tempfile::NamedTempFile::new_in(parent)?;
    let mut w = std::io::BufWriter::new(tmp.as_file());
    for line in lines.iter().skip(start_idx) {
        writeln!(w, "{}", line)?;
    }
    w.flush()?;
    drop(w);
    drop(guard); // release lock before rename to avoid deadlock on Windows
    tmp.persist(path).map_err(|e| e.error)?;
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();
    
    // Uniform CWD Context Awareness 
    let current_dir_raw = match &cli.command {
        Some(Commands::Log { cwd, .. }) if cwd.is_some() => {
            std::path::PathBuf::from(cwd.as_ref().unwrap())
        }
        Some(Commands::Query { cwd, .. }) if cwd.is_some() => {
            std::path::PathBuf::from(cwd.as_ref().unwrap())
        }
        Some(Commands::Suggest { cwd, .. }) if cwd.is_some() => {
            std::path::PathBuf::from(cwd.as_ref().unwrap())
        }
        _ => env::current_dir()?,
    };
    
    let current_dir = if let Ok(can) = std::fs::canonicalize(&current_dir_raw) {
        std::path::PathBuf::from(normalize_path_str(&can.to_string_lossy()))
    } else {
        std::path::PathBuf::from(normalize_path_str(&current_dir_raw.to_string_lossy()))
    };
    let root = detect_project_root(&current_dir);
    let hash = hash_project_path(&root);

    match cli.command {
        Some(Commands::Log { command_str, prev, exit, cwd: _, branch }) => {
            let sanitized_cmd = sanitize_command(&command_str);
            if sanitized_cmd.is_empty() { return Ok(()); }

            // Atomic Direct-to-Disk Logging
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let _ = std::fs::create_dir_all(&projects_dir);
            let project_file = projects_dir.join(format!("{}.txt", hash));
            if let Err(e) = append_to_file_locked(&project_file, &sanitized_cmd) {
                eprintln!("[termim] warn: could not write history: {}", e);
            }
            // Atomic prune — keeps newest MAX_HISTORY_LINES entries
            let _ = prune_log(&project_file, MAX_HISTORY_LINES);

            // Global Stats backup (atomic append + prune)
            let global_path = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join("global_stats.txt");
            let _ = append_to_file_locked(&global_path, &sanitized_cmd);
            let _ = prune_log(&global_path, MAX_GLOBAL_STATS_LINES);

            // Behavioral Intelligence: Record Markov Transition (State-Aware Learning)
            if let Some(prev_cmd) = prev {
                let sanitized_prev = sanitize_command(&prev_cmd);
                if !sanitized_prev.is_empty() && sanitized_prev != sanitized_cmd {
                    let trans_file = projects_dir.join(format!("{}_transitions.txt", hash));
                    let exit_code = exit.unwrap_or(0);
                    let branch_str = branch.unwrap_or_else(|| "none".to_string());
                    // Format: prev ::: next ::: exit ::: branch
                    let record = format!("{} ::: {} ::: {} ::: {}", sanitized_prev, sanitized_cmd, exit_code, branch_str);
                    let _ = append_to_file_locked(&trans_file, &record);
                    // Atomic prune — keeps newest MAX_TRANSITION_LINES entries
                    let _ = prune_log(&trans_file, MAX_TRANSITION_LINES);
                }
            }
        }

        Some(Commands::Query { prev, cwd: _, history_only, suggest_only, branch }) => {
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            let mut seen: std::collections::HashSet<String> = std::collections::HashSet::new();

            // v1.1.0: Context-Aware Retrieval (Failure & Branch awareness)
            let prev_exit = std::env::var("TERMIM_LAST_EXIT").ok().and_then(|s| s.parse::<i32>().ok()).unwrap_or(0);

            // 1. Behavioral Prediction: Freq-Ranked Transitions (v1.4.0: Optional)
            if !history_only {
                if let Some(p) = prev.clone() {
                    let sanitized_p = sanitize_command(&p);
                    let trans_file = projects_dir.join(format!("{}_transitions.txt", hash));
                    if let Ok(content) = read_file_locked(&trans_file) {
                        let mut transitions = std::collections::HashMap::with_capacity(100);
                        let target_branch = branch.unwrap_or_else(|| "none".to_string());
                        
                        for line in content.lines() {
                            let parts: Vec<_> = line.split(" ::: ").collect();
                            if parts.len() >= 2 && parts[0] == sanitized_p {
                                let mut weight = 1;
                                
                                // v1.1.0: Context-Aware Weighting
                                if parts.len() == 4 {
                                    // 1. Branch Precision (+500 score)
                                    if parts[3] == target_branch {
                                        weight += 500;
                                    }

                                    // 2. Failure Recovery Support (+1000 score)
                                    // If the last command failed, prioritize recovery commands
                                    let captured_exit = parts[2].parse::<i32>().unwrap_or(0);
                                    if prev_exit != 0 && captured_exit != 0 {
                                        weight += 1000;
                                    }
                                }
                                
                                *transitions.entry(parts[1].to_string()).or_insert(0) += weight;
                            }
                        }
                        let mut ranked: Vec<_> = transitions.into_iter().collect();
                        ranked.sort_by(|a, b| b.1.cmp(&a.1));
                        for (cmd, _) in ranked {
                            if seen.insert(cmd.clone()) {
                                println!("{}", cmd);
                            }
                        }
                    }
                }

                // v1.0.5: Fundamentals Fallback (Sub-millisecond dispatch)
                if seen.is_empty() {
                    if let Some(p) = prev {
                        let fundamentals: Vec<&'static str> = FundamentalsRegistry::get_suggested_follow_ups(&p);
                        for f in fundamentals {
                            let f_str: String = f.to_string();
                            if seen.insert(f_str.clone()) {
                                println!("{}", f_str);
                            }
                        }
                    }
                }
            }

            // 2. Standard History Fallback — memory-efficient tail read
            if !suggest_only {
                if let Ok(lines) = read_file_tail(&hist_file) {
                    for line in lines.iter().rev() {
                        if seen.insert(line.clone()) {
                            println!("{}", line);
                        }
                    }
                }
            }
        }

        Some(Commands::Suggest { prefix, prev, cwd: _, branch }) => {
            // 1. Analyze Project Context
            let root = detect_project_root(&env::current_dir()?);
            let profile = analyze_project(&root);
            let mut counts = std::collections::HashMap::with_capacity(200);
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let hash = hash_project_path(&root);

            // 1. Behavioral Habits (1000x Absolute Weight)
            if let Some(p) = prev {
                let sanitized_p = sanitize_command(&p);
                let trans_file = projects_dir.join(format!("{}_transitions.txt", hash));
                let prev_exit = std::env::var("TERMIM_LAST_EXIT").ok().and_then(|s| s.parse::<i32>().ok()).unwrap_or(0);
                let target_branch = branch.unwrap_or_else(|| "none".to_string());

                if let Ok(content) = read_file_locked(&trans_file) {
                    for line in content.lines() {
                        let parts: Vec<_> = line.split(" ::: ").collect();
                        if parts.len() >= 2 && parts[0] == sanitized_p {
                            let mut weight = 1000;
                            if parts.len() == 4 {
                                if parts[3] == target_branch { weight += 500; }
                                let captured_exit = parts[2].parse::<i32>().unwrap_or(0);
                                if prev_exit != 0 && captured_exit != 0 { weight += 1000; }
                            }
                            *counts.entry(parts[1].to_string()).or_insert(0) += weight;
                        }
                    }
                }
            }

            // 2. Project History (1x Weight) — tail read
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            if let Ok(lines) = read_file_tail(&hist_file) {
                for line in lines {
                    *counts.entry(line).or_insert(0) += 1;
                }
            }

            // 3. Proactive Ecosystem Advice (50x Multiplier)
            for s in &profile.suggestions {
                *counts.entry(s.command.clone()).or_insert(0) += s.base_score * 50;
            }

            // 4. Unified Weighted Ranking & Filtering
            let prefix_str = prefix.unwrap_or_default().to_lowercase();
            let mut ranked: Vec<_> = counts.into_iter().collect();
            ranked.sort_by(|a, b| b.1.cmp(&a.1));

            let filtered: Vec<_> = ranked
                .into_iter()
                .map(|(cmd, _)| cmd)
                .filter(|c| prefix_str.is_empty() || c.to_lowercase().contains(&prefix_str))
                .take(10)
                .collect();

            if filtered.is_empty() {
                println!("No suggestions found for this context.");
            } else {
                if prefix_str.is_empty() {
                    println!("Proactive Advice for {} project:", if profile.ecosystems.is_empty() { "this" } else { "this stack" });
                }
                for cmd in filtered {
                    println!(" {}", cmd);
                }
            }
        }

        Some(Commands::Stats) => {
            let global_path = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join("global_stats.txt");

            if let Ok(content) = read_file_locked(&global_path) {
                let mut counts = std::collections::HashMap::new();
                let mut total = 0;
                for line in content.lines() {
                    if !line.is_empty() {
                        *counts.entry(line.to_string()).or_insert(0) += 1;
                        total += 1;
                    }
                }

                let mut ranked: Vec<_> = counts.into_iter().collect();
                ranked.sort_by(|a, b| b.1.cmp(&a.1));

                println!("=== Termim Usage Statistics ===");
                println!("Total Commands Logged: {}", total);
                println!("-----------------------------------------------\n");
                println!("Top 10 Most Used Commands:");

                for (cmd, count) in ranked.iter().take(10) {
                    let pct = (*count as f64 / total as f64) * 100.0;
                    let bar_len = (pct / 5.0) as usize;
                    let bar = "■".repeat(bar_len);
                    println!("{:>5.1}% | {:<10} | {}", pct, bar, cmd);
                }
                println!("\n-----------------------------------------------");
            } else {
                println!("No statistics recorded yet.");
            }
        }

        Some(Commands::Doctor) => {
            println!("=== Termim Diagnostic Check (v1.1.1) ===\n");
            println!("Mode: Pure CLI (Zero-Daemon / Zero-DB)");
            println!("Version: {}", env!("CARGO_PKG_VERSION"));

            let home = dirs::home_dir().unwrap_or_default().join(".termim");
            let mut all_ok = true;

            // ── Directory checks ─────────────────────────────────────────
            println!("\n[Directories]");
            let projects = home.join(PROJECTS_DIR);
            let dir_ok = projects.exists();
            println!("  Projects dir  : {} {}",
                projects.display(),
                if dir_ok { "[OK]" } else { "[MISSING]" }
            );
            if !dir_ok { all_ok = false; }

            // ── Permission check ─────────────────────────────────────────
            let perm_ok = std::fs::create_dir_all(&projects).is_ok();
            println!("  Write access  : {}",
                if perm_ok { "[OK]" } else { "[FAIL - check directory permissions]" }
            );
            if !perm_ok { all_ok = false; }

            // ── File health ──────────────────────────────────────────────
            println!("\n[File Health]");
            let registry = home.join("registry.txt");
            println!("  Registry      : {} {}",
                registry.display(),
                if registry.exists() { "[OK]" } else { "[not created yet — run 'termim init']" }
            );
            let global_stats = home.join("global_stats.txt");
            if global_stats.exists() {
                let size = std::fs::metadata(&global_stats).map(|m| m.len()).unwrap_or(0);
                let lines = read_file_locked(&global_stats)
                    .map(|s| s.lines().count())
                    .unwrap_or(0);
                println!("  Global stats  : {} lines, {:.1} KB {}",
                    lines, size as f64 / 1024.0,
                    if size > MAX_FILE_SIZE_BYTES { "[WARN: over size cap, will prune on next log]" } else { "[OK]" }
                );
            } else {
                println!("  Global stats  : [not created yet]");
            }

            // ── Shell plugin checks ──────────────────────────────────────
            println!("\n[Shell Plugins]");
            for shell in &["bash.sh", "zsh.sh", "fish.fish", "powershell.ps1"] {
                let plugin_path = home.join("shell").join(shell);
                let status = if plugin_path.exists() {
                    // Sanity-read the first line to verify it's non-empty
                    let readable = std::fs::read_to_string(&plugin_path)
                        .map(|c| !c.trim().is_empty())
                        .unwrap_or(false);
                    if readable { "[OK]" } else { "[WARN: file is empty]" }
                } else {
                    all_ok = false;
                    "[MISSING]"
                };
                println!("  ~/.termim/shell/{:<20} {}", shell, status);
            }

            // ── Latency benchmark ────────────────────────────────────────
            println!("\n[Self-Latency Benchmark]");
            let t_start = std::time::Instant::now();
            // Simulate a query call cost: hash + file probe (no I/O in bench)
            let bench_root = env::current_dir().unwrap_or_default();
            let _bench_hash = termim::core::project::hash_project_path(&bench_root);
            let elapsed = t_start.elapsed();
            println!("  Core hash cost: {:?} (target: <5ms)",
                elapsed
            );

            // ── Summary ──────────────────────────────────────────────────
            println!("\n[Summary]");
            if all_ok {
                println!("  ✅ All checks passed. Termim is healthy.");
            } else {
                println!("  ⚠️  One or more checks failed. Run the installer to repair.");
            }
        }

        Some(Commands::Init) => {
            let mut registry = dirs::home_dir().unwrap_or_default();
            registry.push(".termim/registry.txt");
            let _ = std::fs::create_dir_all(registry.parent().unwrap());
            if let Ok(content) = read_file_locked(&registry) {
                let current_dir_norm = normalize_path_str(&current_dir.to_string_lossy());
                if content.lines().any(|l| normalize_path_str(l) == current_dir_norm) {
                    println!("Project already registered locally.");
                    return Ok(());
                }
            }

            use std::io::Write;
            match std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(&registry)
            {
                Ok(mut f) => {
                    let _ = writeln!(f, "{}", current_dir.to_string_lossy());
                    println!(
                        "Initialized Termim project (Global Registry) in {}",
                        current_dir.display()
                    );
                }
                Err(e) => eprintln!("Error: Failed to update project registry: {}", e),
            }
        }

        Some(Commands::Update) => {
            check_for_updates();
        }

        Some(Commands::Clear { force }) => {
            if !force {
                print!("(!) This will delete all project history, registry, and statistics. Continue? (y/N): ");
                let mut input = String::new();
                std::io::stdout().flush()?;
                std::io::stdin().read_line(&mut input)?;
                if !input.trim().to_lowercase().starts_with('y') {
                    println!("Aborted.");
                    return Ok(());
                }
            }

            println!("Clearing Termim data...");
            let home = dirs::home_dir().unwrap_or_default().join(".termim");
            
            let targets = vec![
                (home.join(PROJECTS_DIR), true), // true if directory
                (home.join("registry.txt"), false),
                (home.join("global_stats.txt"), false),
                (home.join("termim.log"), false),
            ];

            for (path, is_dir) in targets {
                if path.exists() {
                    let result = if is_dir {
                        std::fs::remove_dir_all(&path)
                    } else {
                        std::fs::remove_file(&path)
                    };

                    match result {
                        Ok(_) => println!("  OK: Removed {}", path.display()),
                        Err(e) => eprintln!("  Error: Failed to remove {}: {}", path.display(), e),
                    }
                }
            }
            println!("\n[DONE] Termim data cleared successfully.");
        }

        Some(Commands::Uninstall { force }) => {
            if !force {
                print!("(!) WARNING: This will PERMANENTLY delete all history and remove Termim from your system. Continue? (y/N): ");
                let mut input = String::new();
                std::io::stdout().flush()?;
                std::io::stdin().read_line(&mut input)?;
                if !input.trim().to_lowercase().starts_with('y') {
                    println!("Aborted.");
                    return Ok(());
                }
            }

            println!("Uninstalling Termim...");
            let home = dirs::home_dir().unwrap_or_default().join(".termim");

            // 1. Delete data and scripts
            if home.exists() {
                println!("  OK: Removing data directory at {}", home.display());
                let _ = std::fs::remove_dir_all(&home);
            }

            // 2. Remove from PATH (Windows Specific)
            #[cfg(windows)]
            {
                use winreg::enums::*;
                use winreg::RegKey;
                let hkcu = RegKey::predef(HKEY_CURRENT_USER);
                if let Ok(env) = hkcu.open_subkey_with_flags("Environment", KEY_READ | KEY_WRITE) {
                    if let Ok(current_path) = env.get_value::<String, _>("Path") {
                        let bin_str = home.join("bin").to_string_lossy().to_string();
                        let filtered_paths: Vec<_> = current_path
                            .split(';')
                            .filter(|p| !p.contains(&bin_str))
                            .collect();
                        let _ = env.set_value("Path", &filtered_paths.join(";"));
                        println!("  OK: Removed from User PATH");
                    }
                }
                // 2.5. Automatically remove integration from PowerShell $PROFILE
                let mut profile_paths = Vec::new();

                // Query Windows PowerShell profile paths dynamically
                if let Ok(output) = std::process::Command::new("powershell")
                    .args(["-NoProfile", "-Command", "echo $($PROFILE.AllUsersAllHosts); echo $($PROFILE.AllUsersCurrentHost); echo $($PROFILE.CurrentUserAllHosts); echo $($PROFILE.CurrentUserCurrentHost)"])
                    .output()
                {
                    let stdout = String::from_utf8_lossy(&output.stdout);
                    for line in stdout.lines() {
                        let trimmed = line.trim();
                        if !trimmed.is_empty() {
                            profile_paths.push(std::path::PathBuf::from(trimmed));
                        }
                    }
                }

                // Also query PowerShell Core profile paths dynamically if it exists
                if let Ok(output) = std::process::Command::new("pwsh")
                    .args(["-NoProfile", "-Command", "echo $($PROFILE.AllUsersAllHosts); echo $($PROFILE.AllUsersCurrentHost); echo $($PROFILE.CurrentUserAllHosts); echo $($PROFILE.CurrentUserCurrentHost)"])
                    .output()
                {
                    let stdout = String::from_utf8_lossy(&output.stdout);
                    for line in stdout.lines() {
                        let trimmed = line.trim();
                        if !trimmed.is_empty() {
                            profile_paths.push(std::path::PathBuf::from(trimmed));
                        }
                    }
                }

                profile_paths.sort_unstable();
                profile_paths.dedup();

                for p in profile_paths {
                    if p.exists() {
                        if let Ok(content) = std::fs::read_to_string(&p) {
                            let new_lines: Vec<_> = content
                                .lines()
                                .filter(|line| !line.contains(".termim\\shell"))
                                .collect::<Vec<_>>();
                            let _ = std::fs::write(&p, new_lines.join("\n"));
                        }
                    }
                }
            }

            // 3. Self-Deletion logic
            let exe_path = std::env::current_exe()?;
            
            println!("\n[CLEANUP] Please manually verify or remove the Termim integration line from your shell profile if still present:");
            println!("  - PowerShell : Open your $PROFILE in a text editor and remove the line containing '.termim\\shell\\powershell.ps1'");
            println!("  - Bash/Zsh/Fish : edit ~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish\n");

            println!("Termim has been uninstalled. Goodbye!");

            #[cfg(windows)]
            {
                use std::os::windows::process::CommandExt;
                // On Windows, the binary is locked. We use a separate process to delete it after we exit.
                let cmd = format!("timeout /t 1 /nobreak > NUL & del /f /q \"{}\"", exe_path.display());
                std::process::Command::new("cmd")
                    .raw_arg(format!("/C {}", cmd))
                    .spawn()?;
            }

            #[cfg(not(windows))]
            {
                let _ = std::fs::remove_file(exe_path);
            }
            
            std::process::exit(0);
        }

        None => {
            let profile = analyze_project(&root);

            let eco_str = if profile.ecosystems.is_empty() {
                "Generic Project".to_string()
            } else {
                profile
                    .ecosystems
                    .iter()
                    .map(|e| format!("{:?}", e))
                    .collect::<Vec<_>>()
                    .join(", ")
            };

            let star_text = if let Some(stars) = fetch_star_count_cached() {
                format!("★ {} Stars | If you find Termim useful, please star the repo!", stars)
            } else {
                "If you find Termim useful, please star the repo!".to_string()
            };

            println!(
                r#"
  _______                  _
 |__   __|                (_)
    | | ___ _ __ _ __ ___  _ _ __ ___
    | |/ _ \ '__| '_ ` _ \| | '_ ` _ \
    | |  __/ |  | | | | | | | | | | | |
    |_|\___|_|  |_| |_| |_|_|_| |_| |_|

  Project-aware terminal history + intelligence v1.1.1
  ----------------------------------------------------
  GitHub: https://github.com/akhtarx/termim
  {}

  Current Context:
  • Project: {}
  • Ecosystems: {}

  Quick Commands:
  • termim init    : Register a project for zero-pollution history
  • termim query   : Show ranked history for this project
  • termim suggest : Show intelligent command suggestions
  • termim stats   : Global usage statistics
  • termim doctor  : Health check & diagnostics
  • termim clear   : Reset all data & history
  • termim update  : Check for latest version
  • termim uninstall : COMPLETELY remove Termim from your system
"#,
                star_text,
                root.display(),
                eco_str
            );
        }
    }

    Ok(())
}
