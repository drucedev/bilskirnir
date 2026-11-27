# Project notes

Bilskirnir: a Quickshell config whose checkout is the live config dir
(`~/.config/quickshell/bilskirnir`). Quickshell loads `shell.qml`, which
imports the QML modules `bar/` (the bar, `Bar.qml` per output) and `common/`
(shared singletons). Each module has its own `qmldir`; add new modules to
`modules` in `scripts/quality.cjs` and `MODULES` in `test/quickshell.test.cjs`.
Keep the root for entry points and tooling config only.

- One user setting: optional, gitignored `local.json` (`outputs`). Add settings
  only for a real per-machine need.
- Catppuccin Mocha colours live in `common/Style.qml`.
- Pure logic goes in `bar/BarLogic.js` and is tested from Node; QML is tested
  offscreen through fixtures in `test/quickshell/`.
- Bar behaviour and live-check gaps: `docs/bar.md`. Vocabulary: `docs/GLOSSARY.md`.

## Checks

Inside the devShell (`nix develop` or direnv):

```sh
make check
make test
```
