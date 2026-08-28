use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(
    name = "termim",
    version = "1.2.0",
    about = "Directory & Context-aware terminal history and command intelligence"
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Log a command to the project-specific history.
    ///
    /// This is called automatically by shell hooks.
    Log {
        /// The command string to log
        command_str: String,
        /// The previous command executed (for behavioral transition logic)
        #[arg(short, long)]
        prev: Option<String>,
        /// The exit code of the log command (Intelligence only learns from 0)
        #[arg(short, long)]
        exit: Option<i32>,
        /// Override the current working directory for accurate project detection
        #[arg(long)]
        cwd: Option<String>,

        /// Log only to history and global stats (pre-execution)
        #[arg(long)]
        pre_exec: bool,
        /// Log only to transitions (post-execution)
        #[arg(long)]
        post_exec: bool,
    },
    /// Query the ranked, project-specific history for the current context.
    ///
    /// Used by shell buffer-swapping for 0ms lag history.
    Query {
        /// The previous command executed (to enable predictive ranking)
        #[arg(short, long)]
        prev: Option<String>,
        /// Override the current working directory for accurate project detection
        #[arg(long)]
        cwd: Option<String>,
        /// Only return pure project history (Recency-First)
        #[arg(long)]
        history_only: bool,
        /// Only return intelligent predictions (Transitions-First)
        #[arg(long)]
        suggest_only: bool,
    },
    /// Display intelligent command suggestions based on the project tech-stack.
    Suggest {
        /// Optional prefix to filter suggestions
        prefix: Option<String>,
        /// The previous command executed (to enable predictive suggestions)
        #[arg(short, long)]
        prev: Option<String>,
        /// Override the current working directory for accurate project detection
        #[arg(long)]
        cwd: Option<String>,
        /// Limit the number of suggestions returned
        #[arg(short, long)]
        limit: Option<usize>,
    },
    /// Show usage statistics. Defaults to the current directory ('this').
    Stats {
        /// Scope of statistics: 'this' (current directory) or 'all' (global).
        #[arg(default_value = "this")]
        scope: String,
    },
    /// Perform a diagnostic health check of the Termim installation and shell plugins.
    Doctor,
    /// Manually register a directory as a Termim project (Zero-Pollution via Global Registry).
    Init,
    /// Check for the latest version of Termim from GitHub.
    Update,
    /// Clear Termim data. Defaults to the current directory ('this').
    Clear {
        /// Scope of data to clear: 'this' (current directory) or 'all' (global).
        #[arg(default_value = "this")]
        scope: String,
        /// Force deletion without confirmation prompt.
        #[arg(short, long)]
        force: bool,
    },
    /// COMPLETELY UNINSTALL Termim (Deletes binary and all history).
    Uninstall {
        /// Force uninstallation without confirmation prompt.
        #[arg(short, long)]
        force: bool,
    },
}
