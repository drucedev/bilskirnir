# Bilskirnir

Thor's Quickshell desktop shell, named after Thor's hall. It currently holds
one component, a top [bar](docs/bar.md) for Niri. This is a personal
configuration, public so others can read or copy it.

## Install

Requires Quickshell 0.3.x and Qt 6.8+; the installer lists any other missing
dependency.

```sh
curl -fsSL https://raw.githubusercontent.com/drucedev/bilskirnir/main/install.sh | sh
```

This clones the repository into `~/.config/quickshell/bilskirnir` (honouring
`XDG_CONFIG_HOME`). Then start it from your compositor's autostart:

```sh
qs --no-duplicate -c bilskirnir
```

## Upgrade

The checkout is the live config, so pull it, or re-run the installer, which
fast-forwards an existing checkout:

```sh
git -C ~/.config/quickshell/bilskirnir pull --ff-only
```

Quickshell reloads changed files, so local edits apply the same way.

## Configure

By default a bar appears on every output. To pick outputs on one machine,
create the untracked `local.json` in the checkout:

```json
{ "outputs": ["DP-5"] }
```

Output names come from `niri msg outputs`. An invalid file logs a warning and
falls back to every output.

## Develop

```sh
direnv allow   # or: nix develop
node --test
```

`qs` comes from the system. See [docs/bar.md](docs/bar.md) for what the suite
covers and the static checks.
