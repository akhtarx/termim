use serde::Deserialize;
use std::io::Read;

#[derive(Deserialize)]
struct GitHubRelease {
    tag_name: String,
}

pub fn check_for_updates() {
    println!("Checking for updates...");

    let current_version = env!("CARGO_PKG_VERSION");
    let url = "https://api.github.com/repos/akhtarx/termim/releases/latest";

    // GitHub requires a User-Agent header
    let response = ureq::get(url)
        .set("User-Agent", "termim-cli-update-check")
        .call();

    match response {
        Ok(res) => {
            let mut body = String::new();
            if res.into_reader().read_to_string(&mut body).is_err() {
                eprintln!("Error: Failed to read update response from GitHub.");
                return;
            }

            match serde_json::from_str::<GitHubRelease>(&body) {
                Ok(release) => {
                    let latest_version = release.tag_name.trim_start_matches('v');
                    
                    if is_newer(current_version, latest_version) {
                        println!("\n🚀 A new version of Termim is available!");
                        println!("Current version: v{}", current_version);
                        println!("Latest version:  v{}", latest_version);
                        println!("\nTo update, run:");
                        if cfg!(windows) {
                            println!("  git pull; .\\installer\\install.ps1");
                        } else {
                            println!("  git pull && bash installer/install.sh");
                        }
                    } else if latest_version != current_version {
                        println!("✅ Termim v{} is up to date (Latest on GitHub: v{}).", current_version, latest_version);
                    } else {
                        println!("✅ Termim is already up to date (v{}).", current_version);
                    }
                }
                Err(_) => {
                    eprintln!("Error: Failed to parse version information from GitHub.");
                }
            }
        }
        Err(e) => {
            eprintln!("Error: Could not connect to GitHub to check for updates: {}", e);
        }
    }
}

fn is_newer(current: &str, latest: &str) -> bool {
    let c_parts: Vec<u32> = current.split('.').filter_map(|s| s.parse().ok()).collect();
    let l_parts: Vec<u32> = latest.split('.').filter_map(|s| s.parse().ok()).collect();

    for (c, l) in c_parts.iter().zip(l_parts.iter()) {
        if l > c { return true; }
        if c > l { return false; }
    }

    l_parts.len() > c_parts.len()
}
