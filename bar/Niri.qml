import QtQuick
import Quickshell
import Quickshell.Io
import "BarLogic.js" as Logic

Scope {
  id: root

  readonly property var focusedWindow: Logic.focusedWindow(windows)
  property int retryDelay: 1000
  property string socketPath: Quickshell.env("NIRI_SOCKET")
  property var windows: []
  property var workspaces: []

  function focus(id) {
    if (!requests.connected || !workspaces.some(workspace => workspace.id === id))
      return false;
    requests.write(JSON.stringify({
      Action: {
        FocusWorkspace: {
          reference: {
            Id: id
          }
        }
      }
    }) + "\n");
    requests.flush();
    return true;
  }
  function reconnect() {
    if (!socketPath)
      return;
    events.connected = true;
    requests.connected = true;
  }
  function scheduleReconnect() {
    if (socketPath && !retry.running)
      retry.start();
  }

  Component.onCompleted: {
    if (!socketPath)
      console.warn("NIRI_SOCKET is unset; workspace controls are unavailable");
    root.reconnect();
  }

  // Niri stops accepting requests on a connection after EventStream.
  Socket {
    id: events

    path: root.socketPath

    parser: SplitParser {
      onRead: data => {
        try {
          const event = JSON.parse(data);
          if (event.Err) {
            console.warn("Niri subscription failed: " + event.Err);
            events.connected = false;
            root.scheduleReconnect();
            return;
          }
          root.workspaces = Logic.workspaceEvent(root.workspaces, event);
          const windows = Logic.windowEvent(root.windows, event);
          if (windows !== root.windows)
            root.windows = windows;
          if (event.WorkspacesChanged)
            root.retryDelay = 1000;
        } catch (error) {
          console.warn("Invalid Niri event: " + error);
        }
      }
    }

    onConnectionStateChanged: {
      if (connected) {
        write('"EventStream"\n');
        flush();
      } else {
        root.windows = [];
        root.workspaces = [];
        root.scheduleReconnect();
      }
    }
    onError: root.scheduleReconnect()
  }
  Socket {
    id: requests

    path: root.socketPath

    parser: SplitParser {
      onRead: data => {
        try {
          const reply = JSON.parse(data);
          if (reply.Err)
            console.warn("Niri action failed: " + reply.Err);
        } catch (error) {
          console.warn("Invalid Niri reply: " + error);
        }
      }
    }

    onConnectionStateChanged: {
      if (!connected)
        root.scheduleReconnect();
    }
    onError: root.scheduleReconnect()
  }
  Timer {
    id: retry

    interval: root.retryDelay

    onTriggered: {
      root.retryDelay = Math.min(root.retryDelay * 2, 30000);
      root.reconnect();
    }
  }
}
