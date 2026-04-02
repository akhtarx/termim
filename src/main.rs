use clap::Parser;
use std::env;
use termim::cli::args::{Cli, Commands};
use termim::core::intelligence::{analyze_project, filter_suggestions};
use termim::core::project::{detect_project_root, hash_project_path};
use termim::utils::constants::PROJECTS_DIR;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();
    let current_dir = env::current_dir()?;
    let root = detect_project_root(&current_dir);
    let hash = hash_project_path(&root);

    match cli.command {
        Some(Commands::Log { command_str }) => {
            // Instant Direct-to-Disk Logging
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let _ = std::fs::create_dir_all(&projects_dir);
            let project_file = projects_dir.join(format!("{}.txt", hash));

            if let Ok(mut f) = std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(&project_file)
            {
                use std::io::Write;
                let _ = writeln!(f, "{}", command_str);
            }

            // Global Stats backup (File-based)
            let global_path = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join("global_stats.txt");
            if let Ok(mut f) = std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(&global_path)
            {
                use std::io::Write;
                let _ = writeln!(f, "{}", command_str);
            }
        }

        Some(Commands::Query) => {
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let hist_file = projects_dir.join(format!("{}.txt", hash));

            if let Ok(content) = std::fs::read_to_string(&hist_file) {
                let mut seen = std::collections::HashSet::new();
                for line in content.lines().rev() {
                    if !line.is_empty() && seen.insert(line) {
                        println!("{}", line);
                    }
                }
            }
        }

        Some(Commands::Suggest { prefix }) => {
            // 1. Analyze Project Context
            let profile = analyze_project(&root);
            let mut candidates = Vec::new();
            let mut seen = std::collections::HashSet::new();

            // 2. Fetch Project History (Weighted by frequency in future)
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            if let Ok(content) = std::fs::read_to_string(&hist_file) {
                for line in content.lines().rev() {
                    if !line.is_empty() && seen.insert(line.to_string()) {
                        candidates.push(line.to_string());
                    }
                }
            }

            // 3. Add Ecosystem Defaults (Proactive Advisor)
            for s in &profile.suggestions {
                if seen.insert(s.command.clone()) {
                    candidates.push(s.command.clone());
                }
            }

            // 4. Performance Filter & Sort
            let prefix_str = prefix.unwrap_or_default().to_lowercase();
            let filtered: Vec<_> = candidates
                .into_iter()
                .filter(|c| prefix_str.is_empty() || c.to_lowercase().contains(&prefix_str))
                .take(10) // Only show the Top 10 for Industrial clarity
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

                println!("=== Termim Industrial Intelligence Dashboard ===");
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
            println!("=== termim doctor (Pure CLI v1.0.0) ===\n");
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

  Project-aware terminal history + intelligence v1.0.0
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
