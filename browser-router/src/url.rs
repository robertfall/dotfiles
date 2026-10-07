//! Turn whatever the desktop passes as %u into a host and a path.

pub struct Target {
    pub host: String,
    pub path: String,
}

impl Target {
    /// The string rules match against: `host/path`.
    pub fn key(&self) -> String {
        format!("{}{}", self.host, self.path)
    }
}

pub fn normalise(input: &str) -> Option<Target> {
    let parsed = ::url::Url::parse(input.trim()).ok()?;
    let host = parsed.host_str()?.to_ascii_lowercase();
    if host.is_empty() {
        return None;
    }
    let path = match parsed.path() {
        "" => "/".to_string(),
        p => p.to_string(),
    };
    Some(Target { host, path })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn key(s: &str) -> Option<String> {
        normalise(s).map(|t| t.key())
    }

    #[test]
    fn drops_scheme_and_keeps_path() {
        assert_eq!(key("https://github.com/ticketsolve/x").as_deref(), Some("github.com/ticketsolve/x"));
    }

    #[test]
    fn lowercases_host_and_drops_port() {
        assert_eq!(key("http://Example.COM:8080/A/b").as_deref(), Some("example.com/A/b"));
    }

    #[test]
    fn drops_query_and_fragment() {
        assert_eq!(key("https://a.b/c?x=1#y").as_deref(), Some("a.b/c"));
    }

    #[test]
    fn bare_host_gets_slash() {
        assert_eq!(key("https://a.b").as_deref(), Some("a.b/"));
    }

    #[test]
    fn keeps_www() {
        assert_eq!(normalise("https://www.a.b/").unwrap().host, "www.a.b");
    }

    #[test]
    fn hostless_uri_is_none() {
        assert!(normalise("mailto:x@y.z").is_none());
        assert!(normalise("not a url").is_none());
        assert!(normalise("file:///tmp/x.html").is_none());
    }
}
