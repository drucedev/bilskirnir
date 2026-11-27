pragma ComponentBehavior: Bound
import QtQuick
import "../common"
import "BarLogic.js" as Logic

Row {
  id: root

  required property var service

  Repeater {
    model: root.service.workspaces

    BarButton {
      required property var modelData

      Accessible.name: Logic.workspaceLabel(modelData) + " on " + modelData.output
      foreground: modelData.is_focused ? Style.accent : Style.inactive
      text: Logic.workspaceIcon(modelData)
      tooltip: Logic.workspaceLabel(modelData)

      onClicked: button => {
        if (button === Qt.LeftButton)
          root.service.focus(modelData.id);
      }
    }
  }
}
