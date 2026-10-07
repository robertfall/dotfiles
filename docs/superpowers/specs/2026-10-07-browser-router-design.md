# browser-router design

Date: 2026-10-07

## Purpose

Clicked links always land in the Firefox profile that `profiles.ini` marks
as default. The OS picks a `.desktop` file, not a profile, and that file
runs `firefox %u` with no profile flag. `browser-router` becomes the default
browser instead. It matches the URL against a rules file, starts Firefox
with the right `-P <profile>`, and records the host it saw. A Hyprland
keybind opens a fuzzel picker that shows recent hosts with the profile
they would get under the current rules and lets the user assign a profile.

Success: a link from any app opens in the profile the rules say. The user
can reassign a host in two fuzzel picks. Adding a rule by CLI, then opening
the picker, shows the new result.

## Not in scope

- URLs reached by browsing inside Firefox. The router never sees them.
- Moving an already open tab between profiles.
- Any browser other than Firefox.
- A long-running daemon or GUI. The router runs and exits.

## Components

One Rust binary, `browser-router`, in `browser-router/` inside the dotfiles
repo. Installed with `cargo install --path browser-router --root ~/.local`
so it lands in `~/.local/bin`. No daemon.

Modules:

- `url` -- normalise a URL to `host/path`.
- `rules` -- load, match, add, remove.
- `recent` -- load, record, cap.
- `profiles` -- read profile names from `profiles.ini`.
- `launch` -- spawn Firefox detached.
- `picker` -- drive fuzzel.
- `cli` -- clap definitions and completion generation.

## CLI

```
browser-router open <url>            match, record, launch  (desktop Exec)
browser-router pick                  fuzzel picker          (Hyprland bind)
browser-router rule <profile> <pat>  add or replace a rule
browser-router rule                  same as rules
browser-router rules                 list rules
browser-router unrule <pat>          remove a rule
browser-router recent                list recent hosts with matched profile
browser-router completions zsh       print zsh completion script
```

Completion: `<profile>` completes from `profiles.ini`. `<pat>` completes
from the recent list. Clap generates the script. `install.sh` links the
generated file into `~/.local/share/zsh/site-functions/_browser-router`,
and `.zshrc` adds that directory to `fpath` before `compinit`.

## Data

Directory: `~/.local/share/browser-router/`. Two plain text files. Both
are read fully at start. Writes go to a temp file in the same directory
then `rename`, so a reader never sees a partial file. No locking.

`rules`: one rule per line, `pattern<TAB>profile`. Lines starting with `#`
and blank lines are ignored. A pattern of `*` is the default profile. The
file is created on first `rule` or `open` with `*<TAB>Personal`. The user
may edit it by hand.

`recent`: one host per line, `host<TAB>unix-seconds`. One line per host.
`record` updates the time of an existing host or appends a new line, then
sorts newest first and truncates to 200 lines. The host is the full
hostname of the URL, lowercased, with no port.

## URL normalisation

Input is any string the desktop passes as `%u`. Parse with the `url`
crate. Output is `host/path` with:

- scheme dropped
- host lowercased, port dropped
- `www.` kept, no stripping
- path kept as given, query and fragment dropped
- a path of `/` gives `host/`

A URL that does not parse or has no host still launches with the default
profile and is not recorded.

## Matching

A pattern with no `/` is a host pattern. It matches when the URL host is
equal to the pattern or ends with `.` + pattern. So `github.com` matches
`github.com` and `gist.github.com`.

A pattern with a `/` is a prefix pattern. It matches when the normalised
`host/path` starts with the pattern. The host part is compared the same
way as a host pattern, so `github.com/ticketsolve/` also matches
`www.github.com/ticketsolve/`. The path part is a plain string prefix.

Among all matching rules the longest pattern wins. A tie is not possible
because `rule` replaces an existing pattern instead of adding a second
line. No match gives the `*` profile. No `*` line gives `Personal`.

## Launch

`open` computes the profile, records the host, then spawns
`firefox -P <profile> <url>`. The child gets `setsid` via `pre_exec`, and
stdin, stdout and stderr point at `/dev/null`. The router does not wait.
It exits with status 0 right after spawn. Firefox's own remote protocol
hands the URL to a running instance of that profile, or starts one.

If `firefox` cannot be spawned, the router prints the error to stderr and
exits 1. The host is still recorded.

## Picker

`pick` loads recent and rules, matches every recent host against the
current rules, and feeds fuzzel `--dmenu` lines of the form:

```
github.com                     Personal
app.ticketsolve.com            Ticketsolve
```

Hosts are newest first. The profile column is the live match. Picking a
line runs fuzzel a second time with the profile names from `profiles.ini`.
Picking a profile writes `rule <profile> <host>`. Escape at either step
exits 0 and writes nothing. The picker only writes host rules. Prefix
rules come from the CLI.

fuzzel is called by name. The graphical session only has `/usr/bin` on
PATH, and fuzzel lives there.

## Profiles

Profile names come from `~/.config/mozilla/firefox/profiles.ini`, every
`[ProfileN]` section's `Name`. The path is `$XDG_CONFIG_HOME/mozilla/firefox/profiles.ini`
with a fallback to `~/.mozilla/firefox/profiles.ini`. `rule` rejects a
profile name that is not in that list.

## Desktop integration

`browser-router/browser-router.desktop`:

```
[Desktop Entry]
Type=Application
Name=Browser Router
Exec=/home/robertherbst/.local/bin/browser-router open %u
Terminal=false
NoDisplay=true
MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;
```

`install.sh` links it to `~/.local/share/applications/browser-router.desktop`
and the completion file as described above. It does not build the binary
and does not change the default browser. The README section in
`CLAUDE.md` gives the two manual steps:

```
cargo install --path browser-router --root ~/.local
xdg-settings set default-web-browser browser-router.desktop
```

`hypr/hyprland.conf` gets one bind:

```
bindd = $mod SHIFT, B, Browser: assign recent links to a profile, exec, ~/.local/bin/browser-router pick
```

The chord is a placeholder. Pick a free one when writing the plan.

## Errors

- Unreadable or missing data files: treated as empty.
- Malformed line in `rules` or `recent`: skipped with no message.
- Unknown profile in `rule`: error to stderr, exit 1.
- fuzzel not found or cancelled: exit 0, nothing written.

## Testing

Unit tests, no network, no Firefox:

- `url`: scheme drop, host lowercase, port drop, query drop, no host.
- `rules`: host match, subdomain match, prefix match, longest wins,
  replace on add, default fallback, missing `*`.
- `recent`: dedupe, newest first, cap at 200, time update.
- `profiles`: parse a sample `profiles.ini`.

`launch` and `picker` are tested by hand: open a link from a terminal with
`xdg-open`, check it lands in the right profile, run `pick`, assign, open
again.
