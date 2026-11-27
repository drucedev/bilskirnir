//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "bar/BarLogic.js" as Logic
import "bar"

ShellRoot {
  id: root

  property var outputs: null

  Niri {
    id: niri
  }

  // Optional, untracked per-machine output list; see README.
  FileView {
    blockLoading: true
    path: Quickshell.shellPath("local.json")
    printErrors: false
    watchChanges: true

    onFileChanged: reload()
    onLoadFailed: root.outputs = null
    onLoaded: {
      try {
        root.outputs = Logic.configuredOutputs(text());
      } catch (error) {
        console.warn("Ignoring local.json:", error.message);
        root.outputs = null;
      }
    }
  }
  Variants {
    model: Quickshell.screens.filter(screen => Logic.showsBar(screen.name, root.outputs))

    Bar {
      service: niri
    }
  }
}
