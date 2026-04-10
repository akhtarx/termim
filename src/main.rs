use clap::Parser;
use regex::Regex;
use std::env;
use std::io::{BufRead, BufReader, Write};
use termim::cli::args::{Cli, Commands};
use termim::core::intelligence::analyze_project;
use termim::core::project::{detect_project_root, hash_project_path};
use termim::utils::constants::PROJECTS_DIR;
use termim::core::fundamentals::FundamentalsRegistry;
use termim::utils::update::check_for_updates;

use once_cell::sync::Lazy;

static PATTERNS: Lazy<Vec<(Regex, &'static str)>> = Lazy::new(|| {
    vec![
        (Regex::new(r"(?i)(-p|--password|--api-key|--token|--pwd)[ =]?[^ ]+").unwrap(), "$1=[REDACTED]"),
        (Regex::new(r"(?i)(password|token|api_key|secret)=[^ ]+").unwrap(), "$1=[REDACTED]"),
        (Regex::new(r"(?i)(bearer|auth)[ =][^ ]+").unwrap(), "$1=[REDACTED]"),
        (Regex::new(r"(?i)(://[^:]+:)[^@]+(@)").unwrap(), "${1}[REDACTED]${2}"),
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

pub fn normalize_path_str(path_str: &str) -> String {
    let mut s = path_str.to_string();
    // Absolute Identity Symmetry:
    // Strip UNC prefixes, normalize separators, and handle platform casing
    if s.starts_with(r"\\?\") {
        s = s[4..].to_string();
    }
    s = s.replace('\\', "/");

    if cfg!(any(target_os = "windows", target_os = "macos")) {
        s.to_lowercase()
    } else {
        s
    }
}

fn append_to_file_locked(path: &std::path::Path, content: &str) -> std::io::Result<()> {
    let f = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .open(path)?;
    let mut lock = fd_lock::RwLock::new(f);
    let mut guard = lock.write()?;
    use std::io::Seek;
    guard.seek(std::io::SeekFrom::End(0))?;
    writeln!(guard, "{}", content)?;
    Ok(())
}

fn read_file_locked(path: &std::path::Path) -> std::io::Result<String> {
    if !path.exists() { return Ok(String::new()); }
    let f = std::fs::File::open(path)?;
    let lock = fd_lock::RwLock::new(f);
    let guard = lock.read()?;
    let mut reader = BufReader::new(&*guard);
    let mut content = String::new();
    use std::io::Read;
    reader.read_to_string(&mut content)?;
    Ok(content)
}

fn prune_log(path: &std::path::Path, max_lines: usize) -> std::io::Result<()> {
    // 1. FAST-FILTER: Check metadata size before attempting expensive lock-and-read.
    if let Ok(meta) = std::fs::metadata(path) {
        if meta.len() < 50_000 { return Ok(()); } 
    }

    // 2. Persistent lock-and-rotate sequence
    let f = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(path)?;
    let mut lock = fd_lock::RwLock::new(f);
    let mut guard = lock.write()?; 

    let reader = BufReader::new(&*guard);
    let lines: Vec<String> = reader.lines().filter_map(Result::ok).collect();

    if lines.len() > max_lines {
        use std::io::Seek;
        guard.set_len(0)?; // Truncate in-place
        guard.seek(std::io::SeekFrom::Start(0))?; // Rewind

        let start_idx = lines.len() - max_lines;
        for line in lines.iter().skip(start_idx) {
            writeln!(guard, "{}", line)?;
        }
    }
    
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

            // Instant Direct-to-Disk Logging
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let _ = std::fs::create_dir_all(&projects_dir);
            let project_file = projects_dir.join(format!("{}.txt", hash));
            let _ = append_to_file_locked(&project_file, &sanitized_cmd);

            // Global Stats backup (File-based)
            let global_path = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join("global_stats.txt");
            let _ = append_to_file_locked(&global_path, &sanitized_cmd);
            let _ = prune_log(&global_path, 5000);

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
                    
                    // Silent Pruning (No-Flood Guarantee)
                    let _ = prune_log(&trans_file, 1000);
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

            // v1.0.9: Context-Aware Retrieval (Failure & Branch awareness)
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
                                
                                // v1.0.9: Context-Aware Weighting
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

            // 2. Standard History Fallback (v1.0.5: Symmetrical Atomic Read)
            if !suggest_only {
                if let Ok(content) = read_file_locked(&hist_file) {
                    for line in content.lines().rev() {
                        if !line.is_empty() && seen.insert(line.to_string()) {
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

            // 2. Project History (1x Weight)
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            if let Ok(content) = read_file_locked(&hist_file) {
                for line in content.lines() {
                    if !line.is_empty() {
                        *counts.entry(line.to_string()).or_insert(0) += 1;
                    }
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
                        *counts.entry(line.to_string()).or_insert(0) += 1000;
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
                    let pct = (*count as f64 / (total * 1000) as f64) * 100.0;
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
            println!("=== Termim Diagnostic Check (v1.0.9) ===\n");
            println!("Mode: Pure CLI (Zero-Daemon)");

            let mut home = dirs::home_dir().unwrap_or_default();
            home.push(".termim");

            let projects = home.join(PROJECTS_DIR);
            println!(
                "Projects: {} {}",
                projects.display(),
                if projects.exists() { "[OK]" } else { "[FAIL]" }
            );

            let registry = home.join("registry.txt");
            println!(
                "Registry: {} {}",
                registry.display(),
                if registry.exists() { "[OK]" } else { "[FAIL]" }
            );

            println!("\nShell plugins:");
            for shell in &["bash.sh", "zsh.sh", "fish.fish", "powershell.ps1"] {
                let exists = if home.join("shell").join(shell).exists() {
                    "[OK]"
                } else {
                    "[FAIL]"
                };
                println!("  ~/.termim/shell/{} {}", shell, exists);
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
            }

            // 3. Self-Deletion logic
            let exe_path = std::env::current_exe()?;
            
            println!("\n[CLEANUP] Please manually remove the Termim integration line from your shell profile:");
            println!("  - PowerShell : rm $PROFILE (search for '.powershell.ps1')");
            println!("  - Bash/Zsh/Fish : edit ~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish\n");

            println!("Termim has been uninstalled. Goodbye!");

            #[cfg(windows)]
            {
                // On Windows, the binary is locked. We use a separate process to delete it after we exit.
                let cmd = format!("timeout /t 1 /nobreak > NUL & del /f \"{}\"", exe_path.display());
                std::process::Command::new("cmd")
                    .args(["/C", &cmd])
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

            println!(
                r#"
  _______                  _
 |__   __|                (_)
    | | ___ _ __ _ __ ___  _ _ __ ___
    | |/ _ \ '__| '_ ` _ \| | '_ ` _ \
    | |  __/ |  | | | | | | | | | | | |
    |_|\___|_|  |_| |_| |_|_|_| |_| |_|

  Project-aware terminal history + intelligence v1.0.9
  ----------------------------------------------------
  GitHub: https://github.com/akhtarx/termim

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
                root.display(),
                eco_str
            );
        }
    }

    Ok(())
}
