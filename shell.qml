//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "BarLogic.js" as Logic

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

    // Quickshell selects the creatable layer-shell backend at runtime.
    // qmllint disable uncreatable-type
    PanelWindow {
      // qmllint enable uncreatable-type
      required property var modelData

      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "quickshell-bar"
      color: Style.background
      exclusiveZone: Style.barHeight
      implicitHeight: Style.barHeight
      screen: modelData

      anchors {
        left: true
        right: true
        top: true
      }
      Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Workspaces {
          service: niri
        }
        FocusedApp {
          service: niri
        }
      }
      Clock {
        anchors.centerIn: parent
      }
      Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        Tray {
        }
        Network {
        }
        Audio {
        }
        Cpu {
        }
        Power {
        }
      }
    }
  }
}
