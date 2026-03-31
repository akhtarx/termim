use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

/// Detected project profile
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ProjectProfile {
    pub ecosystems: Vec<Ecosystem>,
    pub suggestions: Vec<SuggestedCommand>,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum Ecosystem {
    // Web / Frontend frameworks
    Node,
    NestJs,
    Svelte,
    NextJs,
    Vite,
    Nuxt,
    ReactNative,
    // Runtimes
    Deno,
    Bun,
    // Systems
    Rust,
    Cpp,
    Zig,
    // JVM
    Java,
    Kotlin,
    Scala,
    // Scripting / ML
    Python,
    Julia,
    // Backend
    Go,
    PHP,
    Ruby,
    DotNet,
    Elixir,
    Haskell,
    // Mobile
    Flutter,
    Swift,
    // Infrastructure
    Docker,
    Terraform,
    Ansible,
    Kubernetes,
    // Build
    Make,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SuggestedCommand {
    pub command: String,
    pub source: SuggestionSource,
    pub base_score: i64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum SuggestionSource {
    ScriptExtracted,  // Extracted from config files (package.json, Makefile, etc.)
    EcosystemDefault, // Well-known commands for the detected ecosystem
}

// ── Helper ────────────────────────────────────────────────

fn default(cmd: &str, score: i64) -> SuggestedCommand {
    SuggestedCommand {
        command: cmd.to_string(),
        source: SuggestionSource::EcosystemDefault,
        base_score: score,
    }
}

fn extracted(cmd: String, score: i64) -> SuggestedCommand {
    SuggestedCommand {
        command: cmd,
        source: SuggestionSource::ScriptExtracted,
        base_score: score,
    }
}

// ── Analyzer ──────────────────────────────────────────────

/// Analyze a project root and return its full profile with suggestions.
pub fn analyze_project(root: &Path) -> ProjectProfile {
    let mut ecosystems = Vec::new();
    let mut suggestions: Vec<SuggestedCommand> = Vec::new();

    // ── Hoist I/O — read everything once ─────────────────
    // Collect all top-level filenames into a set for O(1) extension checks
    let dir_files: std::collections::HashSet<String> = root
        .read_dir()
        .map(|entries| {
            entries
                .filter_map(|e| e.ok())
                .map(|e| e.file_name().to_string_lossy().to_string())
                .collect()
        })
        .unwrap_or_default();

    let has_ext = |ext: &str| dir_files.iter().any(|f| f.ends_with(ext));

    // Read package.json once — used by Node, NestJS, and React Native
    let pkg_json_path = root.join("package.json");
    let pkg_json_content: Option<String> = if pkg_json_path.exists() {
        fs::read_to_string(&pkg_json_path).ok()
    } else {
        None
    };
    let pkg_json_value: Option<serde_json::Value> = pkg_json_content
        .as_deref()
        .and_then(|s| serde_json::from_str(s).ok());

    // ── Node / JavaScript / TypeScript ───────────────────
    // ── Node / JavaScript / TypeScript ───────────────────
    if pkg_json_path.exists() {
        ecosystems.push(Ecosystem::Node);
        // Use cached JSON — no extra disk read
        if let Some(ref json) = pkg_json_value {
            if let Some(scripts) = json.get("scripts").and_then(|s| s.as_object()) {
                for name in scripts.keys() {
                    suggestions.push(extracted(format!("npm run {}", name), 10));
                }
            }
            // Detect package manager preference from lock files (all cached in dir_files)
            let pm = if dir_files.contains("yarn.lock") {
                "yarn"
            } else if dir_files.contains("pnpm-lock.yaml") {
                "pnpm"
            } else if dir_files.contains("bun.lockb") {
                "bun"
            } else {
                "npm"
            };
            suggestions.push(default(&format!("{} install", pm), 4));
            suggestions.push(default(&format!("{} test", pm), 3));
            suggestions.push(default(&format!("{} run build", pm), 3));
        }
    }

    // ── Rust ─────────────────────────────────────────────
    if root.join("Cargo.toml").exists() {
        ecosystems.push(Ecosystem::Rust);
        for cmd in &[
            "cargo run",
            "cargo build",
            "cargo build --release",
            "cargo test",
            "cargo check",
            "cargo clippy",
            "cargo fmt",
            "cargo clean",
        ] {
            suggestions.push(default(cmd, 5));
        }
    }

    // ── Python ───────────────────────────────────────────
    let has_python = root.join("pyproject.toml").exists()
        || root.join("requirements.txt").exists()
        || root.join("setup.py").exists()
        || root.join("setup.cfg").exists();

    if has_python {
        ecosystems.push(Ecosystem::Python);

        // Django
        if root.join("manage.py").exists() {
            for cmd in &[
                "python manage.py runserver",
                "python manage.py migrate",
                "python manage.py makemigrations",
                "python manage.py createsuperuser",
                "python manage.py shell",
                "python manage.py collectstatic",
            ] {
                suggestions.push(default(cmd, 9));
            }
        }

        // FastAPI / uvicorn
        if root.join("pyproject.toml").exists() {
            if let Ok(c) = fs::read_to_string(root.join("pyproject.toml")) {
                if c.contains("fastapi") || c.contains("uvicorn") {
                    suggestions.push(default("uvicorn main:app --reload", 9));
                }
            }
        }

        for cmd in &[
            "pytest",
            "pytest -v",
            "python main.py",
            "pip install -r requirements.txt",
            "python -m venv .venv",
        ] {
            suggestions.push(default(cmd, 4));
        }

        let activate = if cfg!(target_os = "windows") {
            ".venv\\Scripts\\activate"
        } else {
            "source .venv/bin/activate"
        };
        suggestions.push(default(activate, 4));
    }

    // ── PHP / Laravel / Symfony ───────────────────────────
    let has_composer = root.join("composer.json").exists();
    if has_composer {
        ecosystems.push(Ecosystem::PHP);

        // Laravel (artisan present)
        if root.join("artisan").exists() {
            for cmd in &[
                "php artisan serve",
                "php artisan migrate",
                "php artisan migrate:fresh --seed",
                "php artisan make:model",
                "php artisan make:controller",
                "php artisan make:migration",
                "php artisan queue:work",
                "php artisan config:cache",
                "php artisan route:list",
                "php artisan tinker",
            ] {
                suggestions.push(default(cmd, 9));
            }
        }

        // Extract composer scripts
        if let Ok(content) = fs::read_to_string(root.join("composer.json")) {
            if let Ok(json) = serde_json::from_str::<serde_json::Value>(&content) {
                if let Some(scripts) = json.get("scripts").and_then(|s| s.as_object()) {
                    for name in scripts.keys() {
                        // Skip internal lifecycle hooks
                        if !name.starts_with("pre-") && !name.starts_with("post-") {
                            suggestions.push(extracted(format!("composer run {}", name), 10));
                        }
                    }
                }
            }
        }

        for cmd in &[
            "composer install",
            "composer update",
            "composer dump-autoload",
        ] {
            suggestions.push(default(cmd, 4));
        }
    }

    // ── Ruby / Rails ──────────────────────────────────────
    let has_ruby = root.join("Gemfile").exists();
    if has_ruby {
        ecosystems.push(Ecosystem::Ruby);

        // Rails
        if root.join("config/application.rb").exists() || root.join("config.ru").exists() {
            for cmd in &[
                "rails server",
                "rails console",
                "rails db:migrate",
                "rails db:seed",
                "rails db:reset",
                "rails generate model",
                "rails generate controller",
                "rails routes",
                "rails test",
            ] {
                suggestions.push(default(cmd, 9));
            }
        }

        for cmd in &[
            "bundle install",
            "bundle exec rspec",
            "bundle exec rake",
            "rspec",
            "rubocop",
        ] {
            suggestions.push(default(cmd, 4));
        }
    }

    // ── Java ─────────────────────────────────────────────
    let has_maven = root.join("pom.xml").exists();
    let has_gradle = root.join("build.gradle").exists() || root.join("build.gradle.kts").exists();

    if has_maven {
        ecosystems.push(Ecosystem::Java);
        for cmd in &[
            "mvn spring-boot:run",
            "mvn clean install",
            "mvn test",
            "mvn package",
            "mvn compile",
            "mvn clean",
        ] {
            suggestions.push(default(cmd, 6));
        }
    }

    if has_gradle && !has_maven {
        if !ecosystems.contains(&Ecosystem::Java) {
            ecosystems.push(Ecosystem::Java);
        }
        let gradle_cmd = if root.join("gradlew").exists() {
            "./gradlew"
        } else {
            "gradle"
        };
        for cmd in &["bootRun", "build", "test", "clean", "check", "assemble"] {
            suggestions.push(default(&format!("{} {}", gradle_cmd, cmd), 6));
        }
    }

    // ── .NET / C# ─────────────────────────────────────────
    let has_dotnet = has_ext(".csproj") || has_ext(".sln") || has_ext(".fsproj");
    if has_dotnet {
        ecosystems.push(Ecosystem::DotNet);
        for cmd in &[
            "dotnet run",
            "dotnet build",
            "dotnet test",
            "dotnet publish -c Release",
            "dotnet restore",
            "dotnet clean",
        ] {
            suggestions.push(default(cmd, 6));
        }
    }

    // ── Elixir / Phoenix ──────────────────────────────────
    let has_elixir = root.join("mix.exs").exists();
    if has_elixir {
        ecosystems.push(Ecosystem::Elixir);

        // Phoenix
        let is_phoenix = root.join("config").join("config.exs").exists();
        if is_phoenix {
            for cmd in &[
                "mix phx.server",
                "mix phx.new",
                "mix ecto.migrate",
                "mix ecto.create",
                "mix ecto.reset",
            ] {
                suggestions.push(default(cmd, 9));
            }
        }

        for cmd in &[
            "mix compile",
            "mix test",
            "mix deps.get",
            "mix format",
            "mix credo",
            "iex -S mix",
        ] {
            suggestions.push(default(cmd, 5));
        }
    }

    // ── Flutter / Dart ────────────────────────────────────
    let has_flutter = root.join("pubspec.yaml").exists();
    if has_flutter {
        ecosystems.push(Ecosystem::Flutter);
        for cmd in &[
            "flutter run",
            "flutter build apk",
            "flutter build ios",
            "flutter test",
            "flutter pub get",
            "flutter pub upgrade",
            "flutter clean",
            "flutter analyze",
            "dart pub get",
        ] {
            suggestions.push(default(cmd, 6));
        }
    }

    // ── Swift / Xcode / SPM ──────────────────────────────
    let has_swift = root.join("Package.swift").exists()
        || root
            .read_dir()
            .ok()
            .map(|entries| {
                entries
                    .filter_map(|e| e.ok())
                    .any(|e| e.file_name().to_string_lossy().ends_with(".xcodeproj"))
            })
            .unwrap_or(false);

    if has_swift {
        ecosystems.push(Ecosystem::Swift);
        for cmd in &[
            "swift build",
            "swift test",
            "swift run",
            "swift package resolve",
            "swift package update",
        ] {
            suggestions.push(default(cmd, 5));
        }
    }

    // ── Go ────────────────────────────────────────────────
    if root.join("go.mod").exists() {
        ecosystems.push(Ecosystem::Go);
        for cmd in &[
            "go run .",
            "go build ./...",
            "go test ./...",
            "go mod tidy",
            "go vet ./...",
            "go fmt ./...",
        ] {
            suggestions.push(default(cmd, 5));
        }
    }

    // ── Docker ───────────────────────────────────────────
    let has_docker = dir_files.contains("docker-compose.yml")
        || dir_files.contains("docker-compose.yaml")
        || dir_files.contains("compose.yml");

    if has_docker {
        ecosystems.push(Ecosystem::Docker);
        for cmd in &[
            "docker compose up",
            "docker compose up -d",
            "docker compose down",
            "docker compose build",
            "docker compose logs -f",
            "docker compose ps",
            "docker compose exec app sh",
        ] {
            suggestions.push(default(cmd, 7));
        }
    }

    // ── Makefile ─────────────────────────────────────────
    let makefile = root.join("Makefile");
    if makefile.exists() {
        ecosystems.push(Ecosystem::Make);

        if let Ok(content) = fs::read_to_string(&makefile) {
            for line in content.lines() {
                // Targets are lines like `foo:` at column 0, not starting with tab
                if let Some(target) = line.strip_suffix(':') {
                    let t = target.trim();
                    if !t.is_empty() && !t.starts_with('.') && !t.contains(' ') && !t.contains('$')
                    {
                        suggestions.push(extracted(format!("make {}", t), 8));
                    }
                }
            }
        }
        suggestions.push(default("make", 4));
    }

    // ── NestJS ───────────────────────────────────────────
    // Detect by @nestjs/core in cached package.json content
    if let Some(ref content) = pkg_json_content {
        if content.contains("@nestjs/core") {
            ecosystems.push(Ecosystem::NestJs);
            for cmd in &[
                "nest start",
                "nest start --watch",
                "nest build",
                "nest generate module",
                "nest generate controller",
                "nest generate service",
            ] {
                suggestions.push(default(cmd, 9));
            }
        }
    }

    // ── Svelte / SvelteKit ───────────────────────────────
    if dir_files.contains("svelte.config.js") || dir_files.contains("svelte.config.ts") {
        ecosystems.push(Ecosystem::Svelte);
        for cmd in &[
            "npm run dev",
            "npm run build",
            "npm run preview",
            "npm run check",
            "npm run lint",
        ] {
            suggestions.push(default(cmd, 8));
        }
    }

    // ── Kotlin ───────────────────────────────────────────
    let has_kotlin = has_ext(".kt") || dir_files.contains("build.gradle.kts");
    if has_kotlin && !ecosystems.contains(&Ecosystem::Java) {
        ecosystems.push(Ecosystem::Kotlin);
        // Prefer gradlew if available
        let kw = if root.join("gradlew").exists() {
            "./gradlew"
        } else {
            "gradle"
        };
        for cmd in &["run", "build", "test", "clean", "check"] {
            suggestions.push(default(&format!("{} {}", kw, cmd), 6));
        }
        suggestions.push(default("kotlinc", 4));
    }

    // ── Scala / SBT ──────────────────────────────────────
    if root.join("build.sbt").exists() {
        ecosystems.push(Ecosystem::Scala);
        for cmd in &[
            "sbt run",
            "sbt compile",
            "sbt test",
            "sbt clean",
            "sbt package",
            "sbt assembly",
            "sbt console",
        ] {
            suggestions.push(default(cmd, 6));
        }
    }

    // ── C / C++ / CMake ──────────────────────────────────
    let has_cmake = dir_files.contains("CMakeLists.txt");
    let has_cpp =
        has_cmake || has_ext(".cpp") || has_ext(".cc") || has_ext(".cxx") || has_ext(".c");

    if has_cpp {
        ecosystems.push(Ecosystem::Cpp);
        if has_cmake {
            for cmd in &[
                "cmake -B build",
                "cmake --build build",
                "cmake -B build -DCMAKE_BUILD_TYPE=Release",
                "cmake --build build --target clean",
                "ctest --test-dir build",
            ] {
                suggestions.push(default(cmd, 7));
            }
        } else {
            // Plain Makefile / manual compile fallback
            suggestions.push(default("make", 5));
            suggestions.push(default("gcc -o main main.c", 4));
            suggestions.push(default("g++ -o main main.cpp", 4));
        }
    }

    // ── Next.js ───────────────────────────────────────────
    if dir_files.contains("next.config.js") || dir_files.contains("next.config.ts") {
        ecosystems.push(Ecosystem::NextJs);
        for cmd in &["next dev", "next build", "next start", "next lint"] {
            suggestions.push(default(cmd, 9));
        }
    }

    // ── Vite ──────────────────────────────────────────────
    if dir_files.contains("vite.config.js")
        || dir_files.contains("vite.config.ts")
        || dir_files.contains("vite.config.mjs")
    {
        ecosystems.push(Ecosystem::Vite);
        for cmd in &["vite", "vite build", "vite preview"] {
            suggestions.push(default(cmd, 8));
        }
    }

    // ── Nuxt.js ───────────────────────────────────────────
    if dir_files.contains("nuxt.config.js") || dir_files.contains("nuxt.config.ts") {
        ecosystems.push(Ecosystem::Nuxt);
        for cmd in &["nuxt dev", "nuxt build", "nuxt generate", "nuxt preview"] {
            suggestions.push(default(cmd, 9));
        }
    }

    // ── React Native ─────────────────────────────────────
    if dir_files.contains("react-native.config.js")
        || (dir_files.contains("app.json") && pkg_json_path.exists())
    {
        if let Some(ref c) = pkg_json_content {
            if c.contains("react-native") {
                ecosystems.push(Ecosystem::ReactNative);
                for cmd in &[
                    "npx react-native start",
                    "npx react-native run-android",
                    "npx react-native run-ios",
                    "npx react-native bundle",
                ] {
                    suggestions.push(default(cmd, 9));
                }
            }
        }
    }

    // ── Deno ─────────────────────────────────────────────
    if dir_files.contains("deno.json") || dir_files.contains("deno.jsonc") {
        ecosystems.push(Ecosystem::Deno);
        for cmd in &[
            "deno run",
            "deno task dev",
            "deno task build",
            "deno test",
            "deno lint",
            "deno fmt",
            "deno check",
        ] {
            suggestions.push(default(cmd, 7));
        }
    }

    // ── Bun ──────────────────────────────────────────────
    if dir_files.contains("bun.lockb") || dir_files.contains("bunfig.toml") {
        ecosystems.push(Ecosystem::Bun);
        for cmd in &[
            "bun run dev",
            "bun run build",
            "bun test",
            "bun install",
            "bun add",
            "bun x",
        ] {
            suggestions.push(default(cmd, 8));
        }
    }

    // ── Terraform ────────────────────────────────────────
    if has_ext(".tf") {
        ecosystems.push(Ecosystem::Terraform);
        for cmd in &[
            "terraform init",
            "terraform plan",
            "terraform apply",
            "terraform apply -auto-approve",
            "terraform destroy",
            "terraform fmt",
            "terraform validate",
            "terraform output",
        ] {
            suggestions.push(default(cmd, 8));
        }
    }

    // ── Ansible ──────────────────────────────────────────
    if dir_files.contains("ansible.cfg")
        || dir_files.contains("inventory")
        || dir_files.contains("playbook.yml")
        || dir_files.contains("site.yml")
    {
        ecosystems.push(Ecosystem::Ansible);
        let playbook = if dir_files.contains("playbook.yml") {
            "playbook.yml"
        } else {
            "site.yml"
        };
        for cmd in &[
            &format!("ansible-playbook {}", playbook) as &str,
            &format!("ansible-playbook {} --check", playbook),
            &format!("ansible-playbook {} -i inventory", playbook),
            "ansible all -m ping",
        ] {
            suggestions.push(default(cmd, 8));
        }
    }

    // ── Kubernetes / Helm ─────────────────────────────────
    if root.join("Chart.yaml").exists() || root.join("Chart.yml").exists() {
        ecosystems.push(Ecosystem::Kubernetes);
        for cmd in &[
            "helm install",
            "helm upgrade --install",
            "helm uninstall",
            "helm template .",
            "helm lint",
            "helm package",
        ] {
            suggestions.push(default(cmd, 8));
        }
    } else if dir_files
        .iter()
        .any(|f| f.ends_with(".yaml") && f.contains("deploy"))
    {
        // Raw kubectl manifests (deployment*.yaml at root)
        if !ecosystems.contains(&Ecosystem::Kubernetes) {
            ecosystems.push(Ecosystem::Kubernetes);
        }
        for cmd in &[
            "kubectl apply -f .",
            "kubectl get pods",
            "kubectl get services",
            "kubectl describe pod",
            "kubectl logs -f",
        ] {
            suggestions.push(default(cmd, 7));
        }
    }

    // ── Haskell / Stack / Cabal ───────────────────────────
    if dir_files.contains("stack.yaml") {
        ecosystems.push(Ecosystem::Haskell);
        for cmd in &[
            "stack run",
            "stack build",
            "stack test",
            "stack ghci",
            "stack clean",
        ] {
            suggestions.push(default(cmd, 6));
        }
    } else if has_ext(".cabal") {
        ecosystems.push(Ecosystem::Haskell);
        for cmd in &["cabal run", "cabal build", "cabal test", "cabal repl"] {
            suggestions.push(default(cmd, 6));
        }
    }

    // ── Zig ───────────────────────────────────────────────
    if dir_files.contains("build.zig") {
        ecosystems.push(Ecosystem::Zig);
        for cmd in &[
            "zig build",
            "zig build run",
            "zig build test",
            "zig run",
            "zig test",
            "zig fmt",
        ] {
            suggestions.push(default(cmd, 6));
        }
    }

    // ── Julia ─────────────────────────────────────────────
    // Julia uses Project.toml but so does nothing else (Cargo uses Cargo.toml)
    if dir_files.contains("Project.toml") && !dir_files.contains("Cargo.toml") {
        ecosystems.push(Ecosystem::Julia);
        for cmd in &[
            "julia",
            "julia .",
            "julia --project=. -e 'using Pkg; Pkg.instantiate()'",
            "julia --project=. test/runtests.jl",
        ] {
            suggestions.push(default(cmd, 6));
        }
    }

    // ── Universal git commands ────────────────────────────
    for cmd in &[
        "git status",
        "git add -A && git commit -m \"\"",
        "git push",
        "git pull",
    ] {
        suggestions.push(default(cmd, 2));
    }

    // Deduplicate (keep first occurrence, preserve order)
    let mut seen = std::collections::HashSet::new();
    suggestions.retain(|s| seen.insert(s.command.clone()));

    ProjectProfile {
        ecosystems,
        suggestions,
    }
}

/// Filter suggestions by prefix (case-insensitive substring match).
pub fn filter_suggestions<'a>(
    suggestions: &'a [SuggestedCommand],
    prefix: &str,
) -> Vec<&'a SuggestedCommand> {
    if prefix.is_empty() {
        return suggestions.iter().collect();
    }
    let lower = prefix.to_lowercase();
    suggestions
        .iter()
        .filter(|s| s.command.to_lowercase().contains(&lower))
        .collect()
}
