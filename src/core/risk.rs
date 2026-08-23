#[derive(Debug, PartialEq, Eq)]
pub enum RiskLevel {
    Safe,
    Caution,
    Dangerous,
}

/// Evaluates a command string for destructive or dangerous patterns.
pub fn assess_risk(command: &str) -> RiskLevel {
    let cmd = command.trim();

    let lower_cmd = cmd.to_lowercase();
    let has = |s: &str| lower_cmd.contains(s);

    // 1. Dangerous Commands (Destructive, unrecoverable, or massive mutation)
    if has("rm -rf") || has("rm -r -f") || has("rm -f -r") || has("sudo rm ") {
        return RiskLevel::Dangerous;
    }
    if has("terraform destroy") || has("terraform apply -auto-approve") {
        return RiskLevel::Dangerous;
    }
    if has("kubectl delete") || has("helm uninstall") {
        return RiskLevel::Dangerous;
    }
    if has("git reset --hard") || has("git clean -fd") || has("git clean -f") {
        return RiskLevel::Dangerous;
    }
    if has("drop database") || has("drop table") {
        return RiskLevel::Dangerous;
    }
    if has("migrate:fresh") || has("db:reset") || has("db:drop") {
        return RiskLevel::Dangerous;
    }

    // 2. Caution Commands (Network mutation, production impacting, or credentials)
    if cmd.starts_with("git push") || cmd.starts_with("git push -f") {
        return RiskLevel::Caution;
    }
    if cmd.starts_with("npm publish")
        || cmd.starts_with("cargo publish")
        || cmd.starts_with("gem push")
    {
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
        assert_eq!(assess_risk("sudo rm -rf /"), RiskLevel::Dangerous);
        assert_eq!(assess_risk("rm -r -f foo"), RiskLevel::Dangerous);
        assert_eq!(
            assess_risk("terraform destroy -auto-approve"),
            RiskLevel::Dangerous
        );
        assert_eq!(assess_risk("DROP DATABASE prod;"), RiskLevel::Dangerous);
        assert_eq!(assess_risk("git reset --hard HEAD~1"), RiskLevel::Dangerous);
    }
}
