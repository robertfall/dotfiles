//! The recent file: hosts the router has opened, newest first.
//!
//! One line per host, `host<TAB>unix-seconds`. Capped at CAP lines.

pub const CAP: usize = 200;

#[derive(Debug, Clone, PartialEq)]
pub struct Entry {
    pub host: String,
    pub seen: u64,
}

#[derive(Debug, Default, PartialEq)]
pub struct Recent {
    pub entries: Vec<Entry>,
}

impl Recent {
    pub fn parse(text: &str) -> Recent {
        let mut entries: Vec<Entry> = text
            .lines()
            .filter_map(|raw| {
                let line = raw.trim();
                if line.is_empty() || line.starts_with('#') {
                    return None;
                }
                let (host, seen) = line.split_once('\t')?;
                let seen = seen.trim().parse::<u64>().ok()?;
                let host = host.trim();
                if host.is_empty() {
                    return None;
                }
                Some(Entry { host: host.to_string(), seen })
            })
            .collect();
        entries.sort_by(|a, b| b.seen.cmp(&a.seen));
        Recent { entries }
    }

    pub fn to_text(&self) -> String {
        self.entries
            .iter()
            .map(|e| format!("{}\t{}\n", e.host, e.seen))
            .collect()
    }

    /// Move `host` to the top with time `now`, or add it. Keep at most CAP.
    pub fn record(&mut self, host: &str, now: u64) {
        self.entries.retain(|e| e.host != host);
        self.entries.insert(0, Entry { host: host.to_string(), seen: now });
        self.entries.truncate(CAP);
    }

    pub fn hosts(&self) -> impl Iterator<Item = &str> {
        self.entries.iter().map(|e| e.host.as_str())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_sorts_newest_first_and_skips_bad_lines() {
        let r = Recent::parse("a.b\t10\r\n# c\nbad\nc.d\t20\n e.f \t notanumber \n");
        let hosts: Vec<_> = r.hosts().collect();
        assert_eq!(hosts, vec!["c.d", "a.b"]);
    }

    #[test]
    fn to_text_round_trips() {
        let text = "c.d\t20\na.b\t10\n";
        assert_eq!(Recent::parse(text).to_text(), text);
    }

    #[test]
    fn record_moves_existing_host_to_top() {
        let mut r = Recent::parse("c.d\t20\na.b\t10\n");
        r.record("a.b", 30);
        assert_eq!(r.entries, vec![
            Entry { host: "a.b".into(), seen: 30 },
            Entry { host: "c.d".into(), seen: 20 },
        ]);
    }

    #[test]
    fn record_adds_new_host_at_top() {
        let mut r = Recent::parse("a.b\t10\n");
        r.record("new.io", 11);
        assert_eq!(r.hosts().next(), Some("new.io"));
        assert_eq!(r.entries.len(), 2);
    }

    #[test]
    fn record_caps_at_200() {
        let mut r = Recent::default();
        for i in 0..250 {
            r.record(&format!("h{i}.x"), i);
        }
        assert_eq!(r.entries.len(), CAP);
        assert_eq!(r.hosts().next(), Some("h249.x"));
        assert_eq!(r.hosts().last(), Some("h50.x"));
    }
}
