pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common"

// One bar per output; shell.qml creates it for each selected screen.
// Quickshell selects the creatable layer-shell backend at runtime.
// qmllint disable uncreatable-type
PanelWindow {
  // qmllint enable uncreatable-type
  id: root

  required property var modelData
  required property var service

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
      service: root.service
    }
    FocusedApp {
      service: root.service
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
