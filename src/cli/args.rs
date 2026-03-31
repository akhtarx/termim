use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "termim")]
#[command(version = "0.2.0")]
#[command(about = "Project-aware terminal history + command intelligence", long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Log a command to the project history
    Log {
        /// The command string to log
        command_str: String,
    },
    /// Query ranked project history (used by Up-arrow)
    Query,
    /// Show intelligent suggestions for this project (history + ecosystem detection)
    Suggest {
        /// Optional prefix to filter suggestions
        #[arg(default_value = "")]
        prefix: String,
    },
    /// Show usage statistics for this project
    Stats,
    /// Run health diagnostics (checks daemon, DB, config)
    Doctor,
    /// Manually initialize a project in the current folder (creates a .termim marker)
    Init,
}
