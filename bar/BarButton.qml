import QtQuick
import QtQuick.Controls
import "../common"

Item {
  id: root

  property color foreground: Style.text
  readonly property bool hovered: mouse.containsMouse
  property alias text: label.text
  property string tooltip: ""

  signal clicked(int button)
  signal scrolled(real delta, bool horizontal)

  Accessible.name: tooltip || text
  Accessible.role: Accessible.Button
  implicitHeight: Style.barHeight
  implicitWidth: Math.max(24, label.implicitWidth + 8)

  Accessible.onPressAction: root.clicked(Qt.LeftButton)

  Text {
    id: label

    anchors.centerIn: parent
    color: root.foreground
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    textFormat: Text.PlainText
  }
  MouseArea {
    id: mouse

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    anchors.fill: parent
    hoverEnabled: true

    onClicked: event => root.clicked(event.button)
    onWheel: event => {
      const horizontal = event.angleDelta.y === 0;
      root.scrolled(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
    }
  }
  ToolTip {
    delay: 500
    // Item popups are clipped by the panel's 36px surface.
    popupType: Popup.Window
    text: root.tooltip
    visible: root.hovered && root.tooltip !== ""
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
