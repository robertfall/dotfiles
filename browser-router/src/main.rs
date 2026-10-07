//! browser-router: route clicked links to a Firefox profile.

mod launch;
mod picker;
mod profiles;
mod recent;
mod rules;
mod store;
mod url;

use clap::{Parser, Subcommand};
use std::process::ExitCode;

use recent::Recent;
use rules::Rules;

#[derive(Parser)]
#[command(name = "browser-router", about = "Route clicked links to a Firefox profile")]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Open a URL in the matched profile (the desktop entry calls this)
    Open { url: String },
    /// Fuzzel picker: assign a recent host to a profile (the Hyprland bind calls this)
    Pick,
    /// Add or replace a rule. With no arguments, list rules.
    Rule {
        /// Profile name from profiles.ini
        profile: Option<String>,
        /// Host, host/path prefix, or a full URL
        pattern: Option<String>,
    },
    /// List rules
    Rules {
        /// Print patterns only, one per line
        #[arg(long)]
        patterns: bool,
    },
    /// Remove a rule
    Unrule { pattern: String },
    /// List recent hosts with the profile they match now
    Recent {
        /// Print hosts only, one per line
        #[arg(long)]
        hosts: bool,
    },
    /// List Firefox profile names
    Profiles,
}

/// A CLI pattern argument. A full URL becomes its `host/path`;
/// anything else is used as given, lowercased.
pub fn pattern_from(input: &str) -> String {
    let input = input.trim();
    if input.contains("://") {
        if let Some(t) = url::normalise(input) {
            return t.key();
        }
    }
    rules::canonical(input)
}

fn load_rules() -> Rules {
    Rules::parse(&store::read(&store::rules_path()))
}

fn load_recent() -> Recent {
    Recent::parse(&store::read(&store::recent_path()))
}

fn save_rules(r: &Rules) -> Result<(), String> {
    store::write_atomic(&store::rules_path(), &r.to_text()).map_err(|e| format!("cannot write rules: {e}"))
}

fn save_recent(r: &Recent) -> Result<(), String> {
    store::write_atomic(&store::recent_path(), &r.to_text()).map_err(|e| format!("cannot write recent: {e}"))
}

fn cmd_open(raw: &str) -> Result<(), String> {
    let rules = load_rules();
    let Some(target) = url::normalise(raw) else {
        return launch::firefox(rules.default_profile(), raw).map_err(|e| format!("cannot start firefox: {e}"));
    };
    let profile = rules.profile_for(&target);
    let mut recent = load_recent();
    recent.record(&target.host, store::now());
    if let Err(e) = save_recent(&recent) {
        eprintln!("browser-router: {e}");
    }
    launch::firefox(&profile, raw).map_err(|e| format!("cannot start firefox: {e}"))
}

fn cmd_rule(profile: &str, pattern: &str) -> Result<(), String> {
    let known = profiles::load();
    if !known.iter().any(|p| p == profile) {
        return Err(format!("unknown profile {profile:?}; known: {}", known.join(", ")));
    }
    let mut rules = load_rules();
    rules.set(&pattern_from(pattern), profile);
    save_rules(&rules)
}

fn cmd_rules(patterns_only: bool) {
    let rules = load_rules();
    if patterns_only {
        for r in &rules.rules {
            println!("{}", r.pattern);
        }
        return;
    }
    print!("{}", rules.to_text());
}

fn cmd_unrule(pattern: &str) -> Result<(), String> {
    let mut rules = load_rules();
    if !rules.remove(&pattern_from(pattern)) {
        return Err(format!("no rule for {pattern:?}"));
    }
    save_rules(&rules)
}

fn cmd_recent(hosts_only: bool) {
    let rules = load_rules();
    for host in load_recent().hosts() {
        if hosts_only {
            println!("{host}");
        } else {
            let t = url::Target { host: host.to_string(), path: "/".to_string() };
            println!("{host}\t{}", rules.profile_for(&t));
        }
    }
}

fn cmd_profiles() {
    for p in profiles::load() {
        println!("{p}");
    }
}

fn run(cli: Cli) -> Result<(), String> {
    match cli.cmd {
        Cmd::Open { url } => cmd_open(&url),
        Cmd::Pick => picker::run(),
        Cmd::Rule { profile: None, pattern: None } => {
            cmd_rules(false);
            Ok(())
        }
        Cmd::Rule { profile: Some(p), pattern: Some(pat) } => cmd_rule(&p, &pat),
        Cmd::Rule { .. } => Err("usage: browser-router rule <profile> <pattern>".into()),
        Cmd::Rules { patterns } => {
            cmd_rules(patterns);
            Ok(())
        }
        Cmd::Unrule { pattern } => cmd_unrule(&pattern),
        Cmd::Recent { hosts } => {
            cmd_recent(hosts);
            Ok(())
        }
        Cmd::Profiles => {
            cmd_profiles();
            Ok(())
        }
    }
}

fn main() -> ExitCode {
    match run(Cli::parse()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("browser-router: {e}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pattern_from_url_or_literal() {
        assert_eq!(pattern_from("https://GitHub.com/ticketsolve/app?x=1"), "github.com/ticketsolve/app");
        assert_eq!(pattern_from("GitHub.com"), "github.com");
        assert_eq!(pattern_from("github.com/ticketsolve/"), "github.com/ticketsolve/");
        assert_eq!(pattern_from("*"), "*");
        assert_eq!(pattern_from("GitHub.com/TicketSolve/"), "github.com/TicketSolve/");
    }
}
