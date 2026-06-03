#[cfg(feature = "update-check")]
use serde::Deserialize;
#[cfg(feature = "update-check")]
use std::io::Read;

#[cfg(feature = "update-check")]
#[derive(Deserialize)]
struct GitHubRelease {
    tag_name: String,
}

#[cfg(feature = "update-check")]
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
                        println!("\nTo update to the latest version, run:");
                        if cfg!(windows) {
                            println!("  iex (iwr -useb https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.ps1)");
                        } else {
                            println!("  curl -fsSL https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.sh | bash");
                        }
                    } else if latest_version != current_version {
                        println!(
                            "✅ Termim v{} is up to date (Latest on GitHub: v{}).",
                            current_version, latest_version
                        );
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
            eprintln!(
                "Error: Could not connect to GitHub to check for updates: {}",
                e
            );
        }
    }
}

#[cfg(feature = "update-check")]
pub fn fetch_star_count_cached() -> Option<u64> {
    use std::time::SystemTime;
    let cache_path = dirs::home_dir()
        .unwrap_or_default()
        .join(".termim")
        .join(".star_cache");

    // Check if cache exists and is fresh (< 24 hours)
    if let Ok(metadata) = std::fs::metadata(&cache_path) {
        if let Ok(modified) = metadata.modified() {
            if let Ok(duration) = SystemTime::now().duration_since(modified) {
                if duration.as_secs() < 24 * 60 * 60 {
                    if let Ok(content) = std::fs::read_to_string(&cache_path) {
                        if let Ok(stars) = content.trim().parse::<u64>() {
                            return Some(stars);
                        }
                    }
                }
            }
        }
    }

    // Fetch from GitHub with a short timeout so we don't block startup if offline
    let agent = ureq::AgentBuilder::new()
        .timeout(std::time::Duration::from_millis(1500))
        .build();

    let req = agent
        .get("https://api.github.com/repos/akhtarx/termim")
        .set("User-Agent", "termim-cli");

    if let Ok(response) = req.call() {
        if let Ok(json) = serde_json::from_reader::<_, serde_json::Value>(response.into_reader()) {
            if let Some(stars) = json.get("stargazers_count").and_then(|v| v.as_u64()) {
                // Update cache
                let _ = std::fs::write(&cache_path, stars.to_string());
                return Some(stars);
            }
        }
    }

    // Fallback to old cache if fetch fails
    if let Ok(content) = std::fs::read_to_string(&cache_path) {
        if let Ok(stars) = content.trim().parse::<u64>() {
            return Some(stars);
        }
    }

    None
}

#[cfg(feature = "update-check")]
fn is_newer(current: &str, latest: &str) -> bool {
    let c_parts: Vec<u32> = current.split('.').filter_map(|s| s.parse().ok()).collect();
    let l_parts: Vec<u32> = latest.split('.').filter_map(|s| s.parse().ok()).collect();

    for (c, l) in c_parts.iter().zip(l_parts.iter()) {
        if l > c {
            return true;
        }
        if c > l {
            return false;
        }
    }

    l_parts.len() > c_parts.len()
}

#[cfg(not(feature = "update-check"))]
pub fn check_for_updates() {
    println!("Update check is disabled in this build. Please check https://github.com/akhtarx/termim/releases for updates.");
}

#[cfg(not(feature = "update-check"))]
pub fn fetch_star_count_cached() -> Option<u64> {
    None
}
