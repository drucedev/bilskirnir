pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import "../common"
import "BarLogic.js" as Logic

Item {
  id: root

  readonly property string appId: window && window.app_id ? String(window.app_id) : ""

  // Desktop entries are scanned after startup. A constant applications model
  // does not notify bindings, so the revision forces the name to resolve.
  property int desktopRevision: 0
  readonly property var entry: {
    if (desktopRevision === 0 || appId === "")
      return null;
    return DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
  }
  readonly property string name: desktopRevision === 0 ? "" : Logic.appName(window, entry && entry.name ? entry.name : "")
  required property var service
  readonly property string title: window && window.title ? String(window.title).trim() : ""
  readonly property string tooltip: name !== "" && title !== "" && title !== name ? title : ""
  readonly property var window: service.focusedWindow

  Accessible.name: name
  Accessible.role: Accessible.StaticText
  implicitHeight: Style.barHeight
  implicitWidth: visible ? Math.min(280, label.implicitWidth) : 0
  visible: name !== ""

  Component.onCompleted: {
    if (DesktopEntries.applications.values.length > 0)
      root.desktopRevision = 1;
  }

  Connections {
    function onApplicationsChanged() {
      root.desktopRevision++;
    }

    target: DesktopEntries
  }
  Text {
    id: label

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    color: Style.text
    elide: Text.ElideRight
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    text: root.name
    textFormat: Text.PlainText
    width: parent.width
  }
  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
  }
  ToolTip {
    delay: 500
    popupType: Popup.Window
    text: root.tooltip
    visible: mouse.containsMouse && root.tooltip !== ""
    y: root.height + 2

    background: Rectangle {
      color: Style.base
    }
    contentItem: Text {
      color: Style.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
      text: root.tooltip
      textFormat: Text.PlainText
    }
  }
}
