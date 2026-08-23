use std::process::Command;
use std::env;
use std::path::PathBuf;

fn get_binary_path() -> PathBuf {
    let mut path = env::current_exe().unwrap();
    path.pop();
    if path.ends_with("deps") {
        path.pop();
    }
    path.push("termim");
    if cfg!(windows) {
        path.set_extension("exe");
    }
    path
}

#[test]
fn test_bash_integration() {
    if cfg!(windows) {
        // Skip bash test on standard windows runner unless WSL/GitBash is present
        // In GitHub Actions, we could rely on bash being available, but let's be safe.
        let output = Command::new("bash").arg("-c").arg("echo hi").output();
        if output.is_err() || !output.unwrap().status.success() {
            println!("Skipping bash integration test on Windows (bash not found or WSL not configured)");
            return;
        }
    }

    let bin_path = get_binary_path();
    let status = Command::new("bash")
        .arg("tests/integration/test_bash.sh")
        .env("TERMIM_BIN", bin_path)
        .status()
        .expect("Failed to execute bash");

    assert!(status.success(), "Bash integration test failed");
}

#[test]
fn test_powershell_integration() {
    let pwsh = if cfg!(windows) { "powershell" } else { "pwsh" };
    
    let output = Command::new(pwsh).arg("-Version").output();
    if output.is_err() {
        println!("Skipping PowerShell integration test (powershell/pwsh not found)");
        return;
    }

    let bin_path = get_binary_path();
    let status = Command::new(pwsh)
        .arg("-ExecutionPolicy")
        .arg("Bypass")
        .arg("-File")
        .arg("tests/integration/test_powershell.ps1")
        .env("TERMIM_BIN", bin_path)
        .status()
        .expect("Failed to execute powershell");

    assert!(status.success(), "PowerShell integration test failed");
}

#[test]
fn test_zsh_integration() {
    if cfg!(windows) {
        let output = Command::new("zsh").arg("-c").arg("echo hi").output();
        if output.is_err() || !output.unwrap().status.success() {
            println!("Skipping zsh integration test on Windows (zsh not found)");
            return;
        }
    }

    let bin_path = get_binary_path();
    let status = Command::new("zsh")
        .arg("tests/integration/test_zsh.sh")
        .env("TERMIM_BIN", bin_path)
        .status()
        .expect("Failed to execute zsh");

    assert!(status.success(), "Zsh integration test failed");
}

#[test]
fn test_fish_integration() {
    if cfg!(windows) {
        let output = Command::new("fish").arg("-c").arg("echo hi").output();
        if output.is_err() || !output.unwrap().status.success() {
            println!("Skipping fish integration test on Windows (fish not found)");
            return;
        }
    }

    let bin_path = get_binary_path();
    let status = Command::new("fish")
        .arg("tests/integration/test_fish.fish")
        .env("TERMIM_BIN", bin_path)
        .status()
        .expect("Failed to execute fish");

    assert!(status.success(), "Fish integration test failed");
}
