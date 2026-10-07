//! Where the data files live and how they are written.
//!
//! Writes go to a temp file in the same directory and then rename, so a
//! reader never sees a partial file.

use std::io;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

pub fn data_dir() -> PathBuf {
    let base = std::env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            let home = std::env::var_os("HOME").map(PathBuf::from).unwrap_or_default();
            home.join(".local/share")
        });
    base.join("browser-router")
}

pub fn rules_path() -> PathBuf {
    data_dir().join("rules")
}

pub fn recent_path() -> PathBuf {
    data_dir().join("recent")
}

pub fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

/// File contents, or an empty string when the file is missing or unreadable.
pub fn read(path: &Path) -> String {
    std::fs::read_to_string(path).unwrap_or_default()
}

pub fn write_atomic(path: &Path, text: &str) -> io::Result<()> {
    let dir = path.parent().ok_or_else(|| io::Error::other("path has no parent"))?;
    std::fs::create_dir_all(dir)?;
    let tmp = dir.join(format!(".{}.tmp-{}", path.file_name().unwrap().to_string_lossy(), std::process::id()));
    std::fs::write(&tmp, text)?;
    std::fs::rename(&tmp, path)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn write_then_read_and_overwrite() {
        let dir = tempfile::tempdir().unwrap();
        let p = dir.path().join("sub").join("rules");
        write_atomic(&p, "a\tb\n").unwrap();
        assert_eq!(read(&p), "a\tb\n");
        write_atomic(&p, "c\td\n").unwrap();
        assert_eq!(read(&p), "c\td\n");
        let leftovers: Vec<_> = std::fs::read_dir(p.parent().unwrap()).unwrap().collect();
        assert_eq!(leftovers.len(), 1, "temp file must not remain");
    }

    #[test]
    fn read_missing_is_empty() {
        assert_eq!(read(Path::new("/nonexistent/browser-router/rules")), "");
    }
}
