# Bar

Bilskirnir's bar is a lightweight, Omarchy Quattro-inspired status bar:
a 36px top bar on every output (or those listed in `local.json`), Catppuccin Mocha at 92%
background opacity, and JetBrainsMono Nerd Font. It requires Quickshell 0.3.x
with Networking, PipeWire, and SystemTray support and Qt 6.8+ for windowed
popups (provided by NixOS here), NetworkManager's `nmcli`, Ghostty/btop, and a `power-menu` command in
`$XDG_BIN_HOME` (default `~/.local/bin`).

- Left: Niri workspaces from all outputs, ordered by output and workspace index;
  click to focus by stable ID. Named workspaces show a fixed icon; other workspaces
  show their number once created. The focused workspace is mauve. The focused
  application's name follows the workspaces: its desktop entry name, otherwise its
  app ID, otherwise its window title. Hover shows the window title when that differs.
  The name hides when no window is focused.
- Center: English weekday and 24-hour time; left-click toggles to English date, ISO
  week, and year. No clock tooltip or calendar popup.
- Right: 16px tray icons, network, audio, CPU, and power. Tray icons support
  primary/middle activation, context menus (including submenus), and scrolling.
- Audio: left-click mutes output, right-click mutes the microphone, scroll changes
  output volume in 5% steps, capped at 100%. Muted output is red; hover shows volume.
- Network: wired/Wi-Fi/disconnected icon and signal strength, preferring connected
  wired devices when both are up. Left-click toggles Wi-Fi (also while wired);
  with no wired link, disabled Wi-Fi shows a red Wi-Fi-off icon. A hardware
  rfkill block makes the click a no-op and is named in the tooltip. Hover fetches
  the interface's IP address and, on wired, shows the Wi-Fi state.
- CPU: hover shows total/per-core usage sampled every five seconds without
  subprocesses; left-click opens `ghostty -e btop`.
- Power: left-click opens the existing Fuzzel `power-menu`; hover turns the icon red.

Niri uses a reconnecting event stream for workspaces and windows, and a separate action socket. Audio,
network icons, and tray contents update through native services. The clock ticks
once a minute; `nmcli` runs only to fetch a hovered network tooltip. There is no
plugin framework, background command polling, or additional daemon.

## Running

Your compositor starts `qs --no-duplicate -c bilskirnir` at login; on Niri,
`spawn-at-startup "qs" "--no-duplicate" "-c" "bilskirnir"`. Config reloads do not
run startup commands; to start the bar in an existing Niri session:

```sh
niri msg action spawn -- qs --no-duplicate -c bilskirnir
```

For a foreground development run, use `qs --no-duplicate -c bilskirnir` (Ctrl+C
stops that process), or `qs --no-duplicate -p <checkout>` for another checkout.
Quickshell reloads edited files, including `local.json`. A bar disappears when
its output is disconnected and returns when it reconnects.

## Validation

```sh
node --test
```

The suite needs Node.js, `git`, and `qs`. It tests the production JavaScript and the installer, loads the
clock, audio, and tray components offscreen against stand-in objects, and drives
Niri IPC through a temporary Unix socket. It does not change startup settings.
Network and CPU services, tooltips, launcher commands, real device signals,
popup placement/submenu rendering, `local.json` output selection, and monitor hotplug need a live desktop check.

For static checks, run `node --check` on `BarLogic.js` and the test files, `shellcheck install.sh`, and
`qmllint -W 0` on the config's QML files with the installed Qt and Quickshell QML
import directories supplied via `-I`. Run it from the parent directory
(`-i bilskirnir/qmldir bilskirnir/*.qml`): qmllint 6.12 misreads `-i qmldir`
when the current directory holds that qmldir.
The narrow lint exemptions document Quickshell's runtime-selected PanelWindow
backend and opaque ObjectModel metadata.
