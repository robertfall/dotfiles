//! The rules file: which profile a URL goes to.
//!
//! One rule per line, `pattern<TAB>profile`. A pattern with no slash
//! matches the host and every subdomain. A pattern with a slash is a
//! prefix of `host/path`. The longest matching pattern wins. The
//! pattern `*` is the default profile.

use crate::url::Target;

pub const FALLBACK_PROFILE: &str = "Personal";

#[derive(Debug, Clone, PartialEq)]
pub struct Rule {
    pub pattern: String,
    pub profile: String,
}

#[derive(Debug, Default, PartialEq)]
pub struct Rules {
    pub default: Option<String>,
    pub rules: Vec<Rule>,
}

impl Rules {
    pub fn parse(text: &str) -> Rules {
        let mut out = Rules::default();
        for raw in text.lines() {
            let line = raw.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            let Some((pattern, profile)) = line.split_once('\t') else { continue };
            let (pattern, profile) = (pattern.trim(), profile.trim());
            if pattern.is_empty() || profile.is_empty() {
                continue;
            }
            out.set(pattern, profile);
        }
        out
    }

    pub fn to_text(&self) -> String {
        let mut s = String::new();
        if let Some(d) = &self.default {
            s.push_str(&format!("*\t{d}\n"));
        }
        for r in &self.rules {
            s.push_str(&format!("{}\t{}\n", r.pattern, r.profile));
        }
        s
    }

    pub fn default_profile(&self) -> &str {
        self.default.as_deref().unwrap_or(FALLBACK_PROFILE)
    }

    /// The longest rule that matches, if any.
    pub fn matched(&self, target: &Target) -> Option<&Rule> {
        self.rules
            .iter()
            .filter(|r| pattern_matches(&r.pattern, target))
            .max_by_key(|r| r.pattern.len())
    }

    pub fn profile_for(&self, target: &Target) -> String {
        match self.matched(target) {
            Some(r) => r.profile.clone(),
            None => self.default_profile().to_string(),
        }
    }

    /// Add a rule, or replace the one with the same pattern.
    pub fn set(&mut self, pattern: &str, profile: &str) {
        if pattern == "*" {
            self.default = Some(profile.to_string());
            return;
        }
        let pattern = canonical(pattern);
        match self.rules.iter_mut().find(|r| r.pattern == pattern) {
            Some(r) => r.profile = profile.to_string(),
            None => self.rules.push(Rule { pattern, profile: profile.to_string() }),
        }
    }

    /// Returns true when a rule was removed.
    pub fn remove(&mut self, pattern: &str) -> bool {
        if pattern == "*" {
            return self.default.take().is_some();
        }
        let pattern = canonical(pattern);
        let before = self.rules.len();
        self.rules.retain(|r| r.pattern != pattern);
        self.rules.len() != before
    }
}

/// Lowercase the host half of a pattern. The path half keeps its case,
/// because URL paths are case-sensitive and match as given.
pub fn canonical(pattern: &str) -> String {
    match pattern.split_once('/') {
        None => pattern.to_ascii_lowercase(),
        Some((h, p)) => format!("{}/{}", h.to_ascii_lowercase(), p),
    }
}

fn host_matches(pattern_host: &str, host: &str) -> bool {
    host == pattern_host
        || (host.len() > pattern_host.len()
            && host.ends_with(pattern_host)
            && host.as_bytes()[host.len() - pattern_host.len() - 1] == b'.')
}

fn pattern_matches(pattern: &str, target: &Target) -> bool {
    match pattern.split_once('/') {
        None => host_matches(pattern, &target.host),
        Some((h, p)) => host_matches(h, &target.host) && target.path.starts_with(&format!("/{p}")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn t(host: &str, path: &str) -> Target {
        Target { host: host.into(), path: path.into() }
    }

    fn rules(text: &str) -> Rules {
        Rules::parse(text)
    }

    #[test]
    fn parses_rules_default_comments_and_crlf() {
        let r = rules("# comment\r\n*\tPersonal\r\n\r\ngithub.com\tWork  \r\nbad line\n");
        assert_eq!(r.default.as_deref(), Some("Personal"));
        assert_eq!(r.rules, vec![Rule { pattern: "github.com".into(), profile: "Work".into() }]);
    }

    #[test]
    fn to_text_round_trips() {
        let text = "*\tPersonal\ngithub.com\tWork\ngithub.com/me/\tPersonal\n";
        assert_eq!(rules(text).to_text(), text);
    }

    #[test]
    fn host_pattern_matches_host_and_subdomains_only() {
        let r = rules("github.com\tWork\n");
        assert_eq!(r.profile_for(&t("github.com", "/")), "Work");
        assert_eq!(r.profile_for(&t("gist.github.com", "/x")), "Work");
        assert_eq!(r.profile_for(&t("notgithub.com", "/")), "Personal");
    }

    #[test]
    fn prefix_pattern_is_a_path_prefix() {
        let r = rules("github.com/ticketsolve/\tWork\n");
        assert_eq!(r.profile_for(&t("github.com", "/ticketsolve/app")), "Work");
        assert_eq!(r.profile_for(&t("www.github.com", "/ticketsolve/app")), "Work");
        assert_eq!(r.profile_for(&t("github.com", "/ticketsolve-fork/app")), "Personal");
        assert_eq!(r.profile_for(&t("github.com", "/other/")), "Personal");
    }

    #[test]
    fn longest_match_wins() {
        let r = rules("github.com\tPersonal\ngithub.com/ticketsolve/\tWork\n");
        assert_eq!(r.profile_for(&t("github.com", "/ticketsolve/x")), "Work");
        assert_eq!(r.profile_for(&t("github.com", "/me/x")), "Personal");
        assert_eq!(r.matched(&t("github.com", "/ticketsolve/x")).unwrap().pattern, "github.com/ticketsolve/");
    }

    #[test]
    fn default_rule_and_fallback() {
        assert_eq!(rules("*\tWork\n").profile_for(&t("a.b", "/")), "Work");
        assert_eq!(rules("").profile_for(&t("a.b", "/")), "Personal");
        assert_eq!(rules("").default_profile(), "Personal");
        assert_eq!(rules("*\tWork\n").default_profile(), "Work");
    }

    #[test]
    fn set_replaces_in_place_and_lowercases() {
        let mut r = rules("github.com\tPersonal\nx.y\tWork\n");
        r.set("GitHub.com", "Work");
        assert_eq!(r.rules[0], Rule { pattern: "github.com".into(), profile: "Work".into() });
        assert_eq!(r.rules.len(), 2);
        r.set("new.io", "Work");
        assert_eq!(r.rules[2].pattern, "new.io");
    }

    #[test]
    fn set_lowercases_host_but_keeps_path_case() {
        let mut r = rules("");
        r.set("GitHub.com/TicketSolve/App", "Work");
        assert_eq!(r.rules[0].pattern, "github.com/TicketSolve/App");
        assert_eq!(r.profile_for(&t("github.com", "/TicketSolve/App/x")), "Work");
        assert!(r.remove("GITHUB.com/TicketSolve/App"));
        assert!(r.rules.is_empty());
    }

    #[test]
    fn set_star_sets_default() {
        let mut r = rules("");
        r.set("*", "Work");
        assert_eq!(r.default.as_deref(), Some("Work"));
        assert!(r.rules.is_empty());
    }

    #[test]
    fn remove_reports_and_handles_star() {
        let mut r = rules("*\tWork\ngithub.com\tWork\n");
        assert!(r.remove("github.com"));
        assert!(!r.remove("github.com"));
        assert!(r.remove("*"));
        assert_eq!(r.default, None);
    }
}
