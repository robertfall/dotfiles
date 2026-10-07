//! Two fuzzel menus: pick a recent host, then pick its profile.
//!
//! The profile shown next to each host is the live match against the
//! current rules, not what happened when the host was recorded. Escape at
//! either step exits 0 and writes nothing.

use std::io::Write;
use std::process::{Command, Stdio};

use crate::recent::Recent;
use crate::rules::Rules;
use crate::url::Target;

/// `host<padding>profile`, newest first.
pub fn lines(recent: &Recent, rules: &Rules) -> Vec<String> {
    recent
        .hosts()
        .map(|host| {
            let t = Target { host: host.to_string(), path: "/".to_string() };
            format!("{host:<40} {}", rules.profile_for(&t))
        })
        .collect()
}

/// The host column of a picker line.
pub fn host_of(line: &str) -> &str {
    line.split_whitespace().next().unwrap_or("")
}

/// fuzzel flags. --only-match stops typed text from coming back as a
/// pick. A fixed-width font and a wide window keep the profile column
/// readable.
fn fuzzel_args(prompt: &str) -> Vec<String> {
    [
        "--dmenu",
        "--only-match",
        "--prompt",
        prompt,
        "--lines",
        "15",
        "--width",
        "72",
        "--font",
        "monospace:size=13",
    ]
    .iter()
    .map(|a| a.to_string())
    .collect()
}

/// Write `host -> profile` into `rules`, but only for a profile that exists.
pub fn assign(rules: &mut Rules, host: &str, profile: &str, known: &[String]) -> Result<(), String> {
    if !known.iter().any(|p| p == profile) {
        return Err(format!("unknown profile {profile:?}"));
    }
    rules.set(host, profile);
    Ok(())
}

/// Show `items` in fuzzel. The chosen line, or None on cancel or error.
fn fuzzel(items: &[String], prompt: &str) -> Option<String> {
    let mut child = Command::new("fuzzel")
        .args(fuzzel_args(prompt))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;
    {
        let mut stdin = child.stdin.take()?;
        for item in items {
            writeln!(stdin, "{item}").ok()?;
        }
    }
    let out = child.wait_with_output().ok()?;
    if !out.status.success() {
        return None;
    }
    let chosen = String::from_utf8_lossy(&out.stdout).trim_end().to_string();
    if chosen.is_empty() {
        None
    } else {
        Some(chosen)
    }
}

pub fn run() -> Result<(), String> {
    let rules = Rules::parse(&crate::store::read(&crate::store::rules_path()));
    let recent = Recent::parse(&crate::store::read(&crate::store::recent_path()));
    let items = lines(&recent, &rules);
    if items.is_empty() {
        return Ok(());
    }
    let Some(chosen) = fuzzel(&items, "host> ") else { return Ok(()) };
    let host = host_of(&chosen).to_string();

    let profiles = crate::profiles::load();
    if profiles.is_empty() {
        return Err("no profiles found in profiles.ini".into());
    }
    let Some(profile) = fuzzel(&profiles, &format!("{host} -> ")) else { return Ok(()) };

    let mut rules = rules;
    assign(&mut rules, &host, &profile, &profiles)?;
    crate::store::write_atomic(&crate::store::rules_path(), &rules.to_text())
        .map_err(|e| format!("cannot write rules: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lines_show_live_match_newest_first() {
        let recent = Recent::parse("github.com\t20\napp.ticketsolve.com\t10\n");
        let rules = Rules::parse("ticketsolve.com\tTicketsolve\n");
        let l = lines(&recent, &rules);
        assert_eq!(l.len(), 2);
        assert!(l[0].starts_with("github.com "));
        assert!(l[0].ends_with("Personal"));
        assert!(l[1].starts_with("app.ticketsolve.com "));
        assert!(l[1].ends_with("Ticketsolve"));
    }

    #[test]
    fn fuzzel_args_only_accept_listed_entries_and_show_the_column() {
        let args = fuzzel_args("host> ");
        assert!(args.iter().any(|a| a == "--only-match"));
        assert!(args.iter().any(|a| a == "--width"));
        assert!(args.iter().any(|a| a.starts_with("monospace")));
    }

    #[test]
    fn assign_rejects_unknown_profile_and_writes_known() {
        let known = vec!["Personal".to_string(), "Work".to_string()];
        let mut rules = Rules::parse("");
        assert!(assign(&mut rules, "a.b", "Personl", &known).is_err());
        assert!(rules.rules.is_empty());
        assert!(assign(&mut rules, "a.b", "Work", &known).is_ok());
        assert_eq!(rules.rules[0].profile, "Work");
    }

    #[test]
    fn host_of_takes_first_column() {
        assert_eq!(host_of("github.com                     Personal"), "github.com");
        assert_eq!(host_of("a.b"), "a.b");
    }
}
