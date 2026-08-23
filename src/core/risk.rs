#[derive(Debug, PartialEq, Eq)]
pub enum RiskLevel {
    Safe,
    Caution,
    Dangerous,
}

/// Evaluates a command string for destructive or dangerous patterns.
pub fn assess_risk(command: &str) -> RiskLevel {
    let cmd = command.trim();
    
    // 1. Dangerous Commands (Destructive, unrecoverable, or massive mutation)
    if cmd.starts_with("rm -rf ") || cmd.starts_with("sudo rm ") {
        return RiskLevel::Dangerous;
    }
    if cmd.starts_with("terraform destroy") || cmd.starts_with("terraform apply -auto-approve") {
        return RiskLevel::Dangerous;
    }
    if cmd.starts_with("kubectl delete") || cmd.starts_with("helm uninstall") {
        return RiskLevel::Dangerous;
    }
    if cmd.starts_with("git reset --hard") || cmd.starts_with("git clean -fd") {
        return RiskLevel::Dangerous;
    }
    let lower_cmd = cmd.to_lowercase();
    if lower_cmd.contains("drop database") || lower_cmd.contains("drop table") {
        return RiskLevel::Dangerous;
    }
    if cmd.contains("migrate:fresh") || cmd.contains("db:reset") {
        return RiskLevel::Dangerous;
    }

    // 2. Caution Commands (Network mutation, production impacting, or credentials)
    if cmd.starts_with("git push") || cmd.starts_with("git push -f") {
        return RiskLevel::Caution;
    }
    if cmd.starts_with("npm publish") || cmd.starts_with("cargo publish") || cmd.starts_with("gem push") {
        return RiskLevel::Caution;
    }
    if cmd.starts_with("docker-compose down") || cmd.starts_with("docker compose down") {
        return RiskLevel::Caution;
    }

    // 3. Safe Commands (Read-only, local development, pure functions)
    RiskLevel::Safe
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_risk_assessment() {
        assert_eq!(assess_risk("ls -la"), RiskLevel::Safe);
        assert_eq!(assess_risk("git status"), RiskLevel::Safe);
        assert_eq!(assess_risk("cargo check"), RiskLevel::Safe);
        
        assert_eq!(assess_risk("git push origin main"), RiskLevel::Caution);
        assert_eq!(assess_risk("npm publish"), RiskLevel::Caution);
        
        assert_eq!(assess_risk("rm -rf node_modules"), RiskLevel::Dangerous);
        assert_eq!(assess_risk("terraform destroy -auto-approve"), RiskLevel::Dangerous);
        assert_eq!(assess_risk("DROP DATABASE prod;"), RiskLevel::Dangerous);
        assert_eq!(assess_risk("git reset --hard HEAD~1"), RiskLevel::Dangerous);
    }
}
