# Project notes

Bilskirnir: a Quickshell config whose checkout is the live config dir
(`~/.config/quickshell/bilskirnir`). Root-level `.qml`, `.js`, and `qmldir`
are what Quickshell loads; keep tooling out of the root otherwise.

- One user setting: optional, gitignored `local.json` (`outputs`). Add settings
  only for a real per-machine need.
- Catppuccin Mocha colours live in `Style.qml`.
- Pure logic goes in `BarLogic.js` and is tested from Node; QML is tested
  offscreen through fixtures in `test/quickshell/`.
- Bar behaviour and live-check gaps: `docs/bar.md`. Vocabulary: `GLOSSARY.md`.

## Checks

Inside the devShell (`nix develop` or direnv):

```sh
make check
make test
```
