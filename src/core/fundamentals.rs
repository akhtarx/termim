/// Termim Fundamentals Engine
/// Static, compiled-in transitions for context-aware developer flows.
/// High-performance, zero disk I/O.

pub struct FundamentalsRegistry;

impl FundamentalsRegistry {
    /// Returns a list of "Fundamental" follow-up commands for a given previous command.
    pub fn get_suggested_follow_ups(prev_cmd: &str) -> Vec<&'static str> {
        let cmd_clean = prev_cmd.trim().to_lowercase();
        let cmd_base = cmd_clean.split_whitespace().next().unwrap_or("");

        // Sub-millisecond static lookup
        match cmd_base {
            // Git Flow (Fundamentals)
            "git" => {
                if cmd_clean.contains(" init") {
                    vec!["git status", "git add ."]
                } else if cmd_clean.contains(" add") {
                    vec!["git status", "git commit -m \"\""]
                } else if cmd_clean.contains(" commit") {
                    vec!["git push", "git status"]
                } else if cmd_clean.contains(" status") {
                    vec!["git add .", "git diff"]
                } else if cmd_clean.contains(" pull") || cmd_clean.contains(" checkout") {
                    vec!["git status"]
                } else {
                    vec!["git status"]
                }
            },

            // Rust / Cargo Flow
            "cargo" => {
                if cmd_clean.contains(" new") || cmd_clean.contains(" init") {
                    vec!["cargo build"]
                } else if cmd_clean.contains(" build") {
                    vec!["cargo run", "cargo test"]
                } else if cmd_clean.contains(" test") {
                    vec!["cargo build"]
                } else if cmd_clean.contains(" run") {
                    vec!["cargo build"]
                } else {
                    vec!["cargo build"]
                }
            },

            // Node / NPM / Yarn Flow
            "npm" | "yarn" | "pnpm" | "bun" => {
                if cmd_clean.contains(" install") || cmd_clean.contains(" i") {
                    vec!["npm start", "npm run dev"]
                } else if cmd_clean.contains(" run build") || cmd_clean.contains(" build") {
                    vec!["npm start", "npm run dev"]
                } else {
                    vec!["npm start", "npm run dev"]
                }
            },

            // Docker Flow
            "docker" => {
                if cmd_clean.contains(" build") {
                    vec!["docker run", "docker images"]
                } else if cmd_clean.contains(" stop") {
                    vec!["docker rm"]
                } else {
                    vec!["docker ps"]
                }
            },

            // Go Flow (v1.6.3)
            "go" => {
                if cmd_clean.contains(" build") {
                    vec!["go run .", "go test ./..."]
                } else if cmd_clean.contains(" test") {
                    vec!["go build"]
                } else if cmd_clean.contains(" run") {
                    vec!["go build"]
                } else {
                    vec!["go build"]
                }
            },

            // Maven Flow (v1.6.3)
            "mvn" => {
                if cmd_clean.contains(" clean") {
                    vec!["mvn install", "mvn compile"]
                } else if cmd_clean.contains(" compile") {
                    vec!["mvn test"]
                } else if cmd_clean.contains(" test") {
                    vec!["mvn clean install"]
                } else {
                    vec!["mvn clean"]
                }
            },

            // Dotnet Flow (v1.6.3)
            "dotnet" => {
                if cmd_clean.contains(" build") {
                    vec!["dotnet run", "dotnet test"]
                } else if cmd_clean.contains(" run") {
                    vec!["dotnet build"]
                } else if cmd_clean.contains(" test") {
                    vec!["dotnet build"]
                } else {
                    vec!["dotnet build"]
                }
            },

            // Terraform Flow (v1.6.3)
            "terraform" => {
                if cmd_clean.contains(" init") {
                    vec!["terraform plan", "terraform validate"]
                } else if cmd_clean.contains(" plan") {
                    vec!["terraform apply", "terraform show"]
                } else if cmd_clean.contains(" apply") {
                    vec!["terraform show", "terraform plan"]
                } else {
                    vec!["terraform plan"]
                }
            },

            // Base OS Navigation
            "cd" => vec!["ls", "ls -la"],
            "mkdir" => vec!["ls", "cd "],
            "rm" | "mv" | "cp" | "clear" => vec!["ls", "ls -la"],

            _ => vec![],
        }
    }
}
