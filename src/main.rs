use clap::Parser;
use std::env;
use std::io::{BufRead, BufReader, Write};
use tempfile::NamedTempFile;
use termim::cli::args::{Cli, Commands};
use termim::core::intelligence::analyze_project;
use termim::core::project::{detect_project_root, hash_project_path};
use termim::utils::constants::PROJECTS_DIR;

fn sanitize_command(command: &str) -> String {
    let mut sanitized = command.to_string();

    // 1. HIGH-SPEED SECRET SCANNER (Multi-Token Manual Sieve)
    let sensitive_keywords = [
        "token", "key", "secret", "password", "pass", "auth", "bearer", "pwd", "private"
    ];

    for key in &sensitive_keywords {
        let mut search_pos = 0;
        while let Some(pos) = sanitized[search_pos..].to_lowercase().find(key) {
            let actual_pos = search_pos + pos;
            let start_of_value = actual_pos + key.len();
            
            // Find the delimiter after the keyword (=, :, or space)
            let remaining = &sanitized[start_of_value..];
            if let Some(delim_pos) = remaining.find(|c: char| c == '=' || c == ':' || c == ' ') {
                let actual_delim_pos = start_of_value + delim_pos;
                // Mask everything after the delimiter until the next space/end
                let next_space = sanitized[actual_delim_pos + 1..].find(|c: char| c == ' ' || c == '\t' || c == '\n');
                let end_pos = if let Some(offset) = next_space {
                    actual_delim_pos + 1 + offset
                } else {
                    sanitized.len()
                };
                
                sanitized.replace_range(actual_delim_pos + 1..end_pos, "***");
                search_pos = actual_delim_pos + 4; // Skip the keyword and mask (***)
            } else {
                search_pos = start_of_value; // No delimiter found, skip this match
            }
            
            if search_pos >= sanitized.len() { break; }
        }
    }

    // 2. HIGH-SPEED URL SCANNER (Masking passwords in URIs)
    if let Some(at_pos) = sanitized.find('@') {
        if let Some(proto_pos) = sanitized[..at_pos].find("://") {
            let creds_start = proto_pos + 3;
            if let Some(colon_pos) = sanitized[creds_start..at_pos].find(':') {
                let actual_colon_pos = creds_start + colon_pos;
                sanitized.replace_range(actual_colon_pos + 1..at_pos, "***");
            }
        }
    }

    sanitized.trim().to_string()
}

fn append_to_file_locked(path: &std::path::Path, content: &str) -> std::io::Result<()> {
    let f = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)?;
    let mut lock = fd_lock::RwLock::new(f);
    let mut guard = lock.write()?;
    writeln!(guard, "{}", content)?;
    Ok(())
}

fn prune_log(path: &std::path::Path, max_lines: usize) -> std::io::Result<()> {
    // 1. FAST-FILTER: Check metadata size before attempting expensive lock-and-read.
    // 1000 lines is roughly 50-80KB and we want a substantial buffer before pruning.
    if let Ok(meta) = std::fs::metadata(path) {
        if meta.len() < 50_000 { return Ok(()); } 
    }

    let lines: Vec<String>;

    // 2. Advisory lock-and-read sequence
    {
        let f = std::fs::OpenOptions::new()
            .read(true)
            .write(true)
            .open(path)?;
        let mut lock = fd_lock::RwLock::new(f);
        let guard = lock.write()?; 
        let reader = BufReader::new(&*guard);
        lines = reader.lines().filter_map(Result::ok).collect();
    } 

    if lines.len() > max_lines {
        // 3. Atomic Write-Rename Strategy
        let parent = path.parent().unwrap_or(std::path::Path::new("."));
        let mut temp = NamedTempFile::new_in(parent)?;
        
        let start_idx = lines.len() - max_lines;
        for line in lines.iter().skip(start_idx) {
            writeln!(temp, "{}", line)?;
        }
        
        // Finalize atomic swap
        temp.persist(path).map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
    }
    
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();
    let current_dir = env::current_dir()?;
    let root = detect_project_root(&current_dir);
    let hash = hash_project_path(&root);

    match cli.command {
        Some(Commands::Log { command_str, prev, exit }) => {
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

            // Behavioral Intelligence: Record Markov Transition (Success-Only Learning)
            if let Some(0) = exit {
                if let Some(prev_cmd) = prev {
                    let sanitized_prev = sanitize_command(&prev_cmd);
                    if !sanitized_prev.is_empty() && sanitized_prev != sanitized_cmd {
                        let trans_file = projects_dir.join(format!("{}_transitions.txt", hash));
                        let record = format!("{} ::: {}", sanitized_prev, sanitized_cmd);
                        let _ = append_to_file_locked(&trans_file, &record);
                        
                        // Silent Pruning (No-Flood Guarantee)
                        let _ = prune_log(&trans_file, 1000);
                    }
                }
            }
        }

        Some(Commands::Query { prev }) => {
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            let mut seen = std::collections::HashSet::new();

            // 1. Behavioral Prediction: Freq-Ranked Transitions (Hardened Delimiter Parsing)
            if let Some(p) = prev {
                let sanitized_p = sanitize_command(&p);
                let trans_file = projects_dir.join(format!("{}_transitions.txt", hash));
                if let Ok(content) = std::fs::read_to_string(&trans_file) {
                    let mut transitions = std::collections::HashMap::with_capacity(100);
                    for line in content.lines() {
                        let parts: Vec<_> = line.split(" ::: ").collect();
                        if parts.len() == 2 && parts[0] == sanitized_p {
                            *transitions.entry(parts[1].to_string()).or_insert(0) += 1;
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

            // 2. Standard History Fallback
            if let Ok(content) = std::fs::read_to_string(&hist_file) {
                for line in content.lines().rev() {
                    if !line.is_empty() && seen.insert(line.to_string()) {
                        println!("{}", line);
                    }
                }
            }
        }

        Some(Commands::Suggest { prefix, prev }) => {
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
                if let Ok(content) = std::fs::read_to_string(&trans_file) {
                    for line in content.lines() {
                        let parts: Vec<_> = line.split(" ::: ").collect();
                        if parts.len() == 2 && parts[0] == sanitized_p {
                            *counts.entry(parts[1].to_string()).or_insert(0) += 1000;
                        }
                    }
                }
            }

            // 2. Project History (1x Weight)
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            if let Ok(content) = std::fs::read_to_string(&hist_file) {
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

            if let Ok(content) = std::fs::read_to_string(&global_path) {
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
                    let bar = "█".repeat(bar_len);
                    println!("{:>5.1}% | {:<12} | {}", pct, bar, cmd);
                }
                println!("\n-----------------------------------------------");
            } else {
                println!("No statistics recorded yet.");
            }
        }

        Some(Commands::Doctor) => {
            println!("=== Termim Diagnostic Check (v1.0.3) ===\n");
            println!("Mode: Pure CLI (Zero-Daemon)");

            let mut home = dirs::home_dir().unwrap_or_default();
            home.push(".termim");

            let projects = home.join(PROJECTS_DIR);
            println!(
                "Projects: {} {}",
                projects.display(),
                if projects.exists() { "✓" } else { "✗" }
            );

            let registry = home.join("registry.txt");
            println!(
                "Registry: {} {}",
                registry.display(),
                if registry.exists() { "✓" } else { "✗" }
            );

            println!("\nShell plugins:");
            for shell in &["zsh.sh", "powershell.ps1"] {
                let exists = if home.join("shell").join(shell).exists() {
                    "✓"
                } else {
                    "✗"
                };
                println!("  ~/.termim/shell/{} {}", shell, exists);
            }
        }

        Some(Commands::Init) => {
            let mut registry = dirs::home_dir().unwrap_or_default();
            registry.push(".termim/registry.txt");
            let _ = std::fs::create_dir_all(registry.parent().unwrap());
            let content = std::fs::read_to_string(&registry).unwrap_or_default();
            let current_dir_str = current_dir.to_string_lossy().to_string();

            if content.lines().any(|l| l == current_dir_str) {
                println!("Project already registered locally.");
            } else {
                use std::io::Write;
                match std::fs::OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open(&registry)
                {
                    Ok(mut f) => {
                        let _ = writeln!(f, "{}", current_dir_str);
                        println!(
                            "Initialized Termim project (Global Registry) in {}",
                            current_dir.display()
                        );
                    }
                    Err(e) => eprintln!("Error: Failed to update project registry: {}", e),
                }
            }
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
  _____                   _
 |_   _|__ _ __ _ __ ___ (_)_ __ ___
   | |/ _ \ '__| '_ ` _ \| | '_ ` _ \
   | |  __/ |  | | | | | | | | | | | |
   |_|\___|_|  |_| |_| |_|_|_| |_| |_|

  Project-aware terminal history + intelligence v1.0.3
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
"#,
                root.display(),
                eco_str
            );
        }
    }

    Ok(())
}
