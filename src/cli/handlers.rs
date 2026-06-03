use crate::cli::args::Commands;
use crate::core::fundamentals::FundamentalsRegistry;
use crate::core::history::{
    append_to_file_locked, prune_log, read_file_locked, read_file_tail, sanitize_command,
};
use crate::core::intelligence::analyze_project;
use crate::core::project::{hash_project_path, normalize_path_str};
use crate::utils::constants::{
    MAX_FILE_SIZE_BYTES, MAX_GLOBAL_STATS_LINES, MAX_HISTORY_LINES, MAX_TRANSITION_LINES,
    PROJECTS_DIR,
};
use crate::utils::update::{check_for_updates, fetch_star_count_cached};
use std::io::Write;
use std::path::PathBuf;

pub fn handle_command(
    command: Commands,
    current_dir: PathBuf,
    root: PathBuf,
    hash: String,
) -> Result<(), Box<dyn std::error::Error>> {
    match command {
        Commands::Log {
            command_str,
            prev,
            exit,
            cwd: _,
            branch,
        } => {
            let sanitized_cmd = sanitize_command(&command_str);
            if sanitized_cmd.is_empty() {
                return Ok(());
            }

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

            // Behavioral Intelligence: Record Behavioral Transition (State-Aware Learning)
            if let Some(prev_cmd) = prev {
                let sanitized_prev = sanitize_command(&prev_cmd);
                if !sanitized_prev.is_empty() && sanitized_prev != sanitized_cmd {
                    let trans_file = projects_dir.join(format!("{}_transitions.txt", hash));
                    let exit_code = exit.unwrap_or(0);
                    let branch_str = branch.unwrap_or_else(|| "none".to_string());
                    // Format: prev ::: next ::: exit ::: branch
                    let record = format!(
                        "{} ::: {} ::: {} ::: {}",
                        sanitized_prev, sanitized_cmd, exit_code, branch_str
                    );
                    let _ = append_to_file_locked(&trans_file, &record);
                    // Atomic prune — keeps newest MAX_TRANSITION_LINES entries
                    let _ = prune_log(&trans_file, MAX_TRANSITION_LINES);
                }
            }
        }

        Commands::Query {
            prev,
            cwd: _,
            history_only,
            suggest_only,
            branch,
        } => {
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            let mut seen: std::collections::HashSet<String> = std::collections::HashSet::new();

            // v1.1.0: Context-Aware Retrieval (Failure & Branch awareness)
            let prev_exit = std::env::var("TERMIM_LAST_EXIT")
                .ok()
                .and_then(|s| s.parse::<i32>().ok())
                .unwrap_or(0);

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
                        ranked.sort_by_key(|b| std::cmp::Reverse(b.1));
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
                        let fundamentals: Vec<&'static str> =
                            FundamentalsRegistry::get_suggested_follow_ups(&p);
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
                if let Ok(lines) = read_file_tail(&hist_file, MAX_HISTORY_LINES) {
                    for line in lines.iter().rev() {
                        if seen.insert(line.clone()) {
                            println!("{}", line);
                        }
                    }
                }
            }

            // 3. Global History Fallback — cross-project recovery
            if !suggest_only {
                let global_path = dirs::home_dir()
                    .unwrap_or_default()
                    .join(".termim")
                    .join("global_stats.txt");

                if let Ok(lines) = read_file_tail(&global_path, MAX_GLOBAL_STATS_LINES) {
                    for line in lines.iter().rev() {
                        if seen.insert(line.clone()) {
                            println!("{}", line);
                        }
                    }
                }
            }
        }

        Commands::Suggest {
            prefix,
            prev,
            cwd: _,
            branch,
        } => {
            let profile = analyze_project(&root);
            let mut counts = std::collections::HashMap::with_capacity(200);
            let projects_dir = dirs::home_dir()
                .unwrap_or_default()
                .join(".termim")
                .join(PROJECTS_DIR);

            // 1. Behavioral Habits (Absolute Weight)
            if let Some(p) = prev {
                let sanitized_p = sanitize_command(&p);
                let trans_file = projects_dir.join(format!("{}_transitions.txt", hash));
                let prev_exit = std::env::var("TERMIM_LAST_EXIT")
                    .ok()
                    .and_then(|s| s.parse::<i32>().ok())
                    .unwrap_or(0);
                let target_branch = branch.unwrap_or_else(|| "none".to_string());

                if let Ok(content) = read_file_locked(&trans_file) {
                    for line in content.lines() {
                        let parts: Vec<_> = line.split(" ::: ").collect();
                        if parts.len() >= 2 && parts[0] == sanitized_p {
                            let mut weight = 1000;
                            if parts.len() == 4 {
                                if parts[3] == target_branch {
                                    weight += 500;
                                }
                                let captured_exit = parts[2].parse::<i32>().unwrap_or(0);
                                if prev_exit != 0 && captured_exit != 0 {
                                    weight += 1000;
                                }
                            }
                            *counts.entry(parts[1].to_string()).or_insert(0) += weight;
                        }
                    }
                }
            }

            // 2. Directory History (1x Weight) — tail read
            let hist_file = projects_dir.join(format!("{}.txt", hash));
            if let Ok(lines) = read_file_tail(&hist_file, MAX_HISTORY_LINES) {
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
            ranked.sort_by_key(|b| std::cmp::Reverse(b.1));

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
                    println!(
                        "Proactive Advice for {} directory:",
                        if profile.ecosystems.is_empty() {
                            "this"
                        } else {
                            "this stack"
                        }
                    );
                }
                for cmd in filtered {
                    println!(" {}", cmd);
                }
            }
        }

        Commands::Stats => {
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
                ranked.sort_by_key(|b| std::cmp::Reverse(b.1));

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

        Commands::Doctor => {
            println!("=== Termim Diagnostic Check (v1.1.5) ===\n");
            println!("Mode: Pure CLI (Zero-Daemon / Zero-DB)");
            println!("Version: {}", env!("CARGO_PKG_VERSION"));

            let home = dirs::home_dir().unwrap_or_default().join(".termim");
            let mut all_ok = true;

            // ── Directory checks ─────────────────────────────────────────
            println!("\n[Directories]");
            let projects = home.join(PROJECTS_DIR);
            let dir_ok = projects.exists();
            println!(
                "  History dir   : {} {}",
                projects.display(),
                if dir_ok { "[OK]" } else { "[MISSING]" }
            );
            if !dir_ok {
                all_ok = false;
            }

            // ── Permission check ─────────────────────────────────────────
            let perm_ok = std::fs::create_dir_all(&projects).is_ok();
            println!(
                "  Write access  : {}",
                if perm_ok {
                    "[OK]"
                } else {
                    "[FAIL - check directory permissions]"
                }
            );
            if !perm_ok {
                all_ok = false;
            }

            // ── File health ──────────────────────────────────────────────
            println!("\n[File Health]");
            let registry = home.join("registry.txt");
            println!(
                "  Registry      : {} {}",
                registry.display(),
                if registry.exists() {
                    "[OK]"
                } else {
                    "[not created yet — run 'termim init']"
                }
            );
            let global_stats = home.join("global_stats.txt");
            if global_stats.exists() {
                let size = std::fs::metadata(&global_stats)
                    .map(|m| m.len())
                    .unwrap_or(0);
                let lines = read_file_locked(&global_stats)
                    .map(|s| s.lines().count())
                    .unwrap_or(0);
                println!(
                    "  Global stats  : {} lines, {:.1} KB {}",
                    lines,
                    size as f64 / 1024.0,
                    if size > MAX_FILE_SIZE_BYTES {
                        "[WARN: over size cap, will prune on next log]"
                    } else {
                        "[OK]"
                    }
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
                    if readable {
                        "[OK]"
                    } else {
                        "[WARN: file is empty]"
                    }
                } else {
                    all_ok = false;
                    "[MISSING]"
                };
                println!("  ~/.termim/shell/{:<20} {}", shell, status);
            }

            // ── Latency check ────────────────────────────────────────────
            println!("\n[Self-Latency Check]");
            let t_start = std::time::Instant::now();
            let _bench_hash = hash_project_path(&current_dir);
            let elapsed = t_start.elapsed();
            println!("  Core hash cost: {:?}", elapsed);

            // ── Summary ──────────────────────────────────────────────────
            println!("\n[Summary]");
            if all_ok {
                println!("  ✅ All checks passed. Termim is healthy.");
            } else {
                println!("  ⚠️  One or more checks failed. Run the installer to repair.");
            }
        }

        Commands::Init => {
            let mut registry = dirs::home_dir().unwrap_or_default();
            registry.push(".termim/registry.txt");
            let _ = std::fs::create_dir_all(registry.parent().unwrap());
            if let Ok(content) = read_file_locked(&registry) {
                let current_dir_norm = normalize_path_str(&current_dir.to_string_lossy());
                if content
                    .lines()
                    .any(|l| normalize_path_str(l) == current_dir_norm)
                {
                    println!("Directory already registered locally.");
                    return Ok(());
                }
            }

            match std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(&registry)
            {
                Ok(mut f) => {
                    let _ = writeln!(f, "{}", current_dir.to_string_lossy());
                    println!(
                        "Initialized Termim directory boundary in {}",
                        current_dir.display()
                    );
                }
                Err(e) => eprintln!("Error: Failed to update project registry: {}", e),
            }
        }

        Commands::Update => {
            check_for_updates();
        }

        Commands::Clear { force } => {
            if !force {
                print!(
                    "(!) This will delete all history, registry, and statistics. Continue? (y/N): "
                );
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

        Commands::Uninstall { force } => {
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
                            let mut new_content = String::new();
                            let mut in_block = false;
                            for line in content.lines() {
                                if line.contains("# >>> termim initialize >>>") {
                                    in_block = true;
                                    continue;
                                }
                                if line.contains("# <<< termim initialize <<<") {
                                    in_block = false;
                                    continue;
                                }
                                if !in_block {
                                    if !line.contains(".termim\\shell") {
                                        new_content.push_str(line);
                                        new_content.push('\n');
                                    }
                                }
                            }
                            let _ = std::fs::write(&p, new_content.trim());
                        }
                    }
                }
            }

            // 2.7. Automatically remove integration from Bash, Zsh, and Fish profile files
            let home_dir = dirs::home_dir().unwrap_or_default();
            let rc_files = vec![
                home_dir.join(".bashrc"),
                home_dir.join(".zshrc"),
                home_dir.join(".config").join("fish").join("config.fish"),
            ];
            for rc_file in rc_files {
                if rc_file.exists() {
                    if let Ok(content) = std::fs::read_to_string(&rc_file) {
                        let mut new_content = String::new();
                        let mut in_block = false;
                        for line in content.lines() {
                            if line.contains("# >>> termim initialize >>>") {
                                in_block = true;
                                continue;
                            }
                            if line.contains("# <<< termim initialize <<<") {
                                  in_block = false;
                                  continue;
                            }
                            if !in_block {
                                if !line.contains(".termim/shell") {
                                    new_content.push_str(line);
                                    new_content.push('\n');
                                }
                            }
                        }
                        let _ = std::fs::write(&rc_file, new_content.trim());
                    }
                }
            }

            // 3. Self-Deletion logic
            let exe_path = std::env::current_exe()?;

            println!("\n[CLEANUP] Please manually verify or remove the Termim integration line from your shell profile if still present:");
            println!("  - PowerShell : Open your $PROFILE in a text editor and remove the line containing '.termim\\shell\\powershell.ps1'");
            println!(
                "  - Bash/Zsh/Fish : edit ~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish\n"
            );

            println!("Termim has been uninstalled. Goodbye!");

            #[cfg(windows)]
            {
                use std::os::windows::process::CommandExt;
                // On Windows, the binary is locked. We use a separate process to delete it after we exit.
                let cmd = format!(
                    "timeout /t 1 /nobreak > NUL & del /f /q \"{}\"",
                    exe_path.display()
                );
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
    }
    Ok(())
}

pub fn show_banner(root: &std::path::Path) {
    let profile = analyze_project(root);
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

    let stars_str = if let Some(stars) = fetch_star_count_cached() {
        format!("★ {} Stars | ", stars)
    } else {
        String::new()
    };

    println!(
        r#"
  _______                  _
 |__   __|                (_)
    | | ___ _ __ _ __ ___  _ _ __ ___
    | |/ _ \ '__| '_ ` _ \| | '_ ` _ \
    | |  __/ |  | | | | | | | | | | | |
    |_|\___|_|  |_| |_| |_|_|_| |_| |_|

  Project-aware terminal history + intelligence v1.1.5
  ----------------------------------------------------
  GitHub: https://github.com/akhtarx/termim
  {}If you find Termim useful, please star the repo!

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
        stars_str,
        root.display(),
        eco_str
    );
}
