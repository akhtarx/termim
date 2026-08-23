use regex::Regex;

fn sanitize_command(command: &str) -> String {
    let mut scrubbed = command.trim().to_string();
    if scrubbed.is_empty() { return scrubbed; }

    let patterns: Vec<(Regex, &'static str)> = vec![
        (Regex::new(r#"(?i)(["']?)(password|token|api[_-]?key|secret|auth|credential|private[_-]?key|access[_-]?key|client[_-]?secret)(["']?)\s*:\s*(["']?)([^\s"',}]+)(["']?)"#).unwrap(), ": [REDACTED]"),
        (Regex::new(r#"(?i)(-p|--password|--api-key|--token|--secret|--pwd|--auth|--credential)([ =]+)(["']?)([^\s"']+)(["']?)"#).unwrap(), "[REDACTED]"),
        (Regex::new(r#"(?i)\b(password|token|api[_-]?key|secret|auth|credential|private[_-]?key|access[_-]?key|client[_-]?secret)=(["']?)([^\s"']+)(["']?)"#).unwrap(), "=[REDACTED]"),
        (Regex::new(r#"(?i)\b(export|set)\s+(\w+)=(["']?)([^\s"']+)(["']?)"#).unwrap(), " =[REDACTED]"),
        (Regex::new(r#"(?i)(bearer|basic|authorization(?:\s*:\s*(?:bearer|basic))?)([ :=]+)(["']?)([^\s"']+)(["']?)"#).unwrap(), "[REDACTED]"),
        (Regex::new(r"(?i)(://[^:]+:)([^@]+)(@)").unwrap(), "[REDACTED]"),
        (Regex::new(r"(?i)\b(ghp_|gho_|github_pat_|sk-|ey[A-Za-z0-9]{10,}|AKIA[0-9A-Z]{16}|xox[baprs]-)[A-Za-z0-9_\-]{8,}").unwrap(), "[REDACTED_TOKEN]"),
        (Regex::new(r"=[A-Za-z0-9+/]{20,}={0,2}").unwrap(), "=[REDACTED_B64]"),
    ];

    for (re, replacement) in patterns.iter() {
        scrubbed = re.replace_all(&scrubbed, *replacement).to_string();
    }
    scrubbed
}

fn main() {
    println!(\"{}\", sanitize_command(\"curl -H 'Authorization: Bearer mytoken'\"));
    println!(\"{}\", sanitize_command(\"curl -H \\\"Authorization: Bearer mytoken\\\"\"));
    println!(\"{}\", sanitize_command(\"PASSWORD=\\\"my_secret\\\" cargo run\"));
    println!(\"{}\", sanitize_command(\"export TOKEN='xyz123'; ./deploy\"));
    println!(\"{}\", sanitize_command(\"mysql --password=\\\"secret_pass\\\" -u root\"));
    println!(\"{}\", sanitize_command(\"aws configure set aws_secret_access_key 'AKIAIOSFODNN7EXAMPLE'\"));
    println!(\"{}\", sanitize_command(\"curl --data '{\\\"token\\\": \\\"secret_value_123\\\", \\\"other\\\": \\\"val\\\"}'\"));
    println!(\"{}\", sanitize_command(\"curl -d '{\\\"api_key\\\":\\\"abc\\\"}'\"));
    println!(\"{}\", sanitize_command(\"git clone https://user:pass123!@github.com/repo\"));
    println!(\"{}\", sanitize_command(\"TOKEN=a PASSWORD=b bash -c 'echo'\"));
}
