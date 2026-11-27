# Bilskirnir

Thor's Quickshell desktop shell: one config holding the desktop components.

## Language

**Bilskirnir**:
The whole shell, one Quickshell config started with `qs -c bilskirnir`.
_Avoid_: bar (for the whole project), Quattro

**Component**:
One user-facing piece of Bilskirnir, such as the bar.
_Avoid_: module, widget

**Bar**:
The top status-bar component, one panel per selected output.
_Avoid_: panel, Waybar

**Checkout**:
The git clone in `~/.config/quickshell/bilskirnir`; it is also the live config.
_Avoid_: install dir

**Local config**:
The optional, untracked `local.json` in the checkout holding per-machine settings.
_Avoid_: settings file, user config
