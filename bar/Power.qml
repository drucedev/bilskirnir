import QtQuick
import Quickshell
import "../common"

BarButton {
  foreground: hovered ? Style.red : Style.text
  text: "󰐥"
  tooltip: "Power\n\nSuper + Alt + Space"

  onClicked: button => {
    if (button === Qt.LeftButton) {
      const bin = Quickshell.env("XDG_BIN_HOME") || Quickshell.env("HOME") + "/.local/bin";
      Quickshell.execDetached([bin + "/power-menu"]);
    }
  }
}
