# Screen share repair runbook

One command does the diagnosis:

```sh
~/.config/hypr/scripts/portal-repair.sh
```

It reads the live compositor directly, so it works from any shell, including
a tmux pane whose environment is stale.

## Escalation

Run these in order. Stop as soon as `check` says healthy.

| Stage | Command | Cost |
|---|---|---|
| 1 | `portal-repair.sh soft` | ~2s, audio keeps playing |
| 2 | `portal-repair.sh env` | ~2s, audio keeps playing |
| 3 | `portal-repair.sh pipewire` | **drops all audio** for a second |
| 4 | `portal-repair.sh hard` | all of the above, plus a hand-launch stopgap |

After any stage, stop the share in the app and start it again. The app holds
its own portal session and will not notice the restart.

## Reading the symptom

**The picker never appears.** The backend is dead, or it is talking to a
compositor that no longer exists. Run `soft`, then `env`.

**The picker appears, the far end sees black or one frozen frame.** PipeWire
is carrying nothing. Run `pipewire`.

**`graphical-session.target` is inactive.** This is the historical failure.
`xdg-desktop-portal.service` has `Requisite=graphical-session.target`, so it
refuses to start and no restart helps. The target only activates because the
session was launched through uwsm. You logged in with the wrong GDM entry.
Real fix: log out, pick **Hyprland (uwsm)**. Stopgap to save a call in
progress: `portal-repair.sh hard`.

## State verified 2026-09-04

Everything below was checked and passing:

- All three GDM session files are installed in `/usr/local/share/wayland-sessions/`.
  `hyprland-managed.desktop` is the visible "Hyprland (uwsm)" entry; the other
  two carry `Hidden=true` and mask the package entries.
- The session is running under uwsm: `wayland-wm@start-hyprland.service` is
  active and `graphical-session.target` is active.
- `xdg-desktop-portal`, `-hyprland` and `-gtk` all running, plus pipewire,
  pipewire-pulse and wireplumber.
- `~/.config/xdg-desktop-portal/hyprland-portals.conf` is symlinked from this
  repo. ScreenCast and Screenshot route to hyprland, Settings routes to gtk.
- ScreenCast on D-Bus answers `AvailableSourceTypes = 7`: monitor, window and
  virtual are all offered.
- Versions: hyprland 0.56.0, xdg-desktop-portal 1.22.0,
  xdg-desktop-portal-hyprland 1.4.0, pipewire 1.6.7, uwsm 0.23.3.

## Sharing app notes

Chrome and the Slack and Discord flatpaks all go through the same portal, so
the stages above cover them.

Firefox has never been run on this machine. It has no profile, so it is not
the safe choice today. If you do use it, note that its webcam path is
separately broken: the C925e is listed but never streams, and the workaround
is `media.webrtc.camera.allow-pipewire=false` in `about:config`. Screen share
itself is unaffected.

OBS is installed and is the quickest pre-flight. Add a "Screen Capture
(PipeWire)" source. If the picker appears, the whole chain works.
