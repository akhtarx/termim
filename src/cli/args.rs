use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "termim", version = "1.0.0", about = "Project-aware terminal history and contextual intelligence")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Log a command to the project-specific history.
    /// This is called automatically by shell hooks.
    Log {
        /// The command string to log
        command_str: String,
    },
    /// Query the ranked, project-specific history for the current context.
    /// Used by shell buffer-swapping for 0ms lag history.
    Query,
    /// Display intelligent command suggestions based on the project tech-stack.
    Suggest {
        /// Optional prefix to filter suggestions
        prefix: Option<String>,
    },
    /// Show global usage statistics analyzed from ~/.termim/global_stats.txt.
    Stats,
    /// Perform a diagnostic health check of the Termim installation and shell plugins.
    Doctor,
    /// Manually register a directory as a Termim project (Zero-Pollution via Global Registry).
    Init,
}
