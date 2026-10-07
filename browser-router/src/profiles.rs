//! Firefox profile names, read from profiles.ini.

use std::path::PathBuf;

/// Every `Name=` inside a `[ProfileN]` section, in file order.
pub fn parse(ini: &str) -> Vec<String> {
    let mut names = Vec::new();
    let mut in_profile = false;
    for raw in ini.lines() {
        let line = raw.trim();
        if line.starts_with('[') {
            in_profile = line.starts_with("[Profile");
            continue;
        }
        if !in_profile {
            continue;
        }
        if let Some(name) = line.strip_prefix("Name=") {
            let name = name.trim();
            if !name.is_empty() {
                names.push(name.to_string());
            }
        }
    }
    names
}

fn candidate_paths() -> Vec<PathBuf> {
    let home = std::env::var_os("HOME").map(PathBuf::from).unwrap_or_default();
    let xdg = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home.join(".config"));
    vec![
        xdg.join("mozilla/firefox/profiles.ini"),
        home.join(".mozilla/firefox/profiles.ini"),
    ]
}

/// Profile names from the first profiles.ini that exists. Empty if none.
pub fn load() -> Vec<String> {
    for p in candidate_paths() {
        if let Ok(text) = std::fs::read_to_string(&p) {
            return parse(&text);
        }
    }
    Vec::new()
}

#[cfg(test)]
mod tests {
    use super::*;

    const INI: &str = "[Profile2]\nName=Ticketsolve\nIsRelative=1\nPath=80448et8.Ticketsolve\n\n[Profile1]\nName=Testing\nPath=u3gwdgno.Testing\n\n[Profile0]\nName=Personal\nPath=xe4kb5a9.default-release\n\n[General]\nStartWithLastProfile=1\nName=NotAProfile\n\n[Install11457493C5A56847]\nDefault=xe4kb5a9.default-release\nLocked=1\n";

    #[test]
    fn reads_profile_names_only() {
        assert_eq!(parse(INI), vec!["Ticketsolve", "Testing", "Personal"]);
    }

    #[test]
    fn empty_input_gives_empty() {
        assert!(parse("").is_empty());
    }
}
