use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "termim", version = "1.0.1", about = "Project-aware terminal history and contextual intelligence")]
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
        /// The previous command executed (for Markov transition logic)
        #[arg(short, long)]
        prev: Option<String>,
        /// The exit code of the log command (Intelligence only learns from 0)
        #[arg(short, long)]
        exit: Option<i32>,
        /// Override the current working directory for accurate project detection
        #[arg(long)]
        cwd: Option<String>,
    },
    /// Query the ranked, project-specific history for the current context.
    /// Used by shell buffer-swapping for 0ms lag history.
    Query {
        /// The previous command executed (to enable predictive ranking)
        #[arg(short, long)]
        prev: Option<String>,
    },
    /// Display intelligent command suggestions based on the project tech-stack.
    Suggest {
        /// Optional prefix to filter suggestions
        prefix: Option<String>,
        /// The previous command executed (to enable predictive suggestions)
        #[arg(short, long)]
        prev: Option<String>,
    },
    /// Show global usage statistics analyzed from ~/.termim/global_stats.txt.
    Stats,
    /// Perform a diagnostic health check of the Termim installation and shell plugins.
    Doctor,
    /// Manually register a directory as a Termim project (Zero-Pollution via Global Registry).
    Init,
}
