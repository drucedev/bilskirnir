//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "BarLogic.js" as Logic

ShellRoot {
    id: root
    property var outputs: null

    Niri { id: niri }

    // Optional, untracked per-machine output list; see README.
    FileView {
        path: Quickshell.shellPath("local.json")
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.outputs = Logic.configuredOutputs(text());
            } catch (error) {
                console.warn("Ignoring local.json:", error.message);
                root.outputs = null;
            }
        }
        onLoadFailed: root.outputs = null
    }

    Variants {
        model: Quickshell.screens.filter(screen => Logic.showsBar(screen.name, root.outputs))

        // Quickshell selects the creatable layer-shell backend at runtime.
        // qmllint disable uncreatable-type
        PanelWindow {
            // qmllint enable uncreatable-type
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Style.barHeight
            color: Style.background
            exclusiveZone: Style.barHeight
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Workspaces { service: niri }
                FocusedApp { service: niri }
            }

            Clock { anchors.centerIn: parent }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                Tray {}
                Network {}
                Audio {}
                Cpu {}
                Power {}
            }
        }
    }
}
