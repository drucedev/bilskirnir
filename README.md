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
make check     # lint and verify formatting without editing files
make fmt       # apply QML and shell formatting
make test      # run the Node and offscreen Quickshell tests
```

`make lint` and `make fmt-check` run the two static checks separately. Qt's
`qmlformat`, `qmllint`, and `qmlls`, plus ShellCheck and shfmt, come from the
dev shell; the runtime `qs` comes from the system. Outside Nix, put these tools
on PATH and set `BILSKIRNIR_QML_IMPORT_PATH` to the colon-separated Qt and
Quickshell QML import directories.

To opt into the pre-commit hook, run `git config --local core.hooksPath .githooks`
from the checkout. Commit from the dev shell (or with the same tools and import
paths available). The hook runs only when a commit touches QML, shell, JavaScript, `qmldir`, or the
Qt tool settings. It checks the staged snapshot, formats only changed files, lints
all staged QML (lint is cross-file), and never rewrites anything.

For editor support, use `qmlls` from the same Qt version. Create an empty
`.qmlls.ini` beside `shell.qml` if it is absent, then run Quickshell so it can
populate the machine-specific paths; the file is ignored by Git.

See [docs/bar.md](docs/bar.md) for validation coverage.
