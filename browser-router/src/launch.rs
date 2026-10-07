//! Start Firefox for a profile and let go of it.
//!
//! One spawn. The child calls setsid so it owns its session and process
//! group, and its stdio points at /dev/null. The router does not wait.
//! When the router exits the kernel reparents Firefox to the user's
//! subreaper. Firefox's own remote protocol hands the URL to a running
//! instance of that profile, or starts one.

use std::io;
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};

pub fn firefox(profile: &str, url: &str) -> io::Result<()> {
    let mut cmd = Command::new("firefox");
    cmd.arg("-P")
        .arg(profile)
        .arg(url)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null());
    // SAFETY: setsid is async-signal-safe and touches no Rust state.
    unsafe {
        cmd.pre_exec(|| {
            if libc::setsid() == -1 {
                return Err(io::Error::last_os_error());
            }
            Ok(())
        });
    }
    cmd.spawn().map(|_| ())
}
