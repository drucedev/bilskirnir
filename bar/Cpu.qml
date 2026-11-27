import QtQuick
import Quickshell
import Quickshell.Io
import "BarLogic.js" as Logic

BarButton {
  id: root

  property var previous: null

  text: "󰍛"
  tooltip: "CPU: collecting usage…"

  onClicked: button => {
    if (button === Qt.LeftButton)
      Quickshell.execDetached(["ghostty", "-e", "btop"]);
  }

  FileView {
    id: stat

    path: "/proc/stat"

    onLoadFailed: {
      root.previous = null;
      root.tooltip = "CPU usage unavailable";
    }
    onLoaded: {
      const sample = Logic.cpuSample(text());
      root.tooltip = Logic.cpuUsage(root.previous, sample);
      root.previous = sample;
    }
  }
  Timer {
    interval: 5000
    repeat: true
    running: true

    onTriggered: stat.reload()
  }
}
