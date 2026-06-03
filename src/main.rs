use clap::Parser;
use std::env;
use termim::cli::args::{Cli, Commands};
use termim::cli::handlers::handle_command;
use termim::core::project::{detect_project_root, hash_project_path, normalize_path_str};

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

    if let Some(cmd) = cli.command {
        handle_command(cmd, current_dir, root, hash)?;
    }

    Ok(())
}
