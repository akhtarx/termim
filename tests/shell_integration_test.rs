use std::env;
use std::path::PathBuf;
use std::process::Command;

fn get_binary_path() -> PathBuf {
    PathBuf::from(env!("CARGO_BIN_EXE_termim"))
}

#[test]
fn test_bash_integration() {
    let bash_exe = if cfg!(windows) {
        "C:\\Program Files\\Git\\bin\\bash.exe"
    } else {
        "bash"
    };

    let output = Command::new(bash_exe).arg("-c").arg("echo hi").output();
    if output.is_err() || !output.unwrap().status.success() {
        println!("Skipping bash integration test (bash not found or failing)");
        return;
    }

    let bin_path = get_binary_path();
    let status = Command::new(bash_exe)
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
    let output = Command::new("zsh").arg("-c").arg("echo hi").output();
    if output.is_err() || !output.unwrap().status.success() {
        println!("Skipping zsh integration test (zsh not found or failing)");
        return;
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
    let output = Command::new("fish").arg("-c").arg("echo hi").output();
    if output.is_err() || !output.unwrap().status.success() {
        println!("Skipping fish integration test (fish not found or failing)");
        return;
    }

    let bin_path = get_binary_path();
    let status = Command::new("fish")
        .arg("tests/integration/test_fish.fish")
        .env("TERMIM_BIN", bin_path)
        .status()
        .expect("Failed to execute fish");

    assert!(status.success(), "Fish integration test failed");
}
