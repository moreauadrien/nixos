import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

Text {
    id: root
    text: NetworkService.icon
    color: NetworkService.connected ? Theme.colorText : Theme.colorTextSubtle
    font.family: Theme.barFontFamily
    font.pixelSize: Theme.barFontSize
    height: Theme.barHeight
    verticalAlignment: Text.AlignVCenter
    Accessible.name: "Network: " + NetworkService.status
    SequentialAnimation on opacity {
        running: NetworkService.busy
        loops: Animation.Infinite
        NumberAnimation { from: 1; to: 0.35; duration: 600 }
        NumberAnimation { from: 0.35; to: 1; duration: 600 }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.QsWindow.window) return;
            const right = root.mapToItem(null, root.width, 0).x;
            popup.margins.right = Math.max(8, root.QsWindow.window.screen.width - right);
            popup.visible = !popup.visible;
        }
    }
    Tooltip {
        anchorItem: root
        screen: root.QsWindow.window ? root.QsWindow.window.screen : null
        text: NetworkService.status + (NetworkService.connected ? " · " + NetworkService.active.name : "")
        wantShow: mouse.containsMouse && !popup.visible
    }
    PanelWindow {
        visible: popup.visible
        screen: root.QsWindow.window ? root.QsWindow.window.screen : null
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea { anchors.fill: parent; onPressed: popup.visible = false }
    }
    PanelWindow {
        id: popup
        visible: false
        screen: root.QsWindow.window ? root.QsWindow.window.screen : null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors { top: true; right: true }
        margins.top: Theme.barHeight + 4
        margins.right: 8
        implicitWidth: 424
        implicitHeight: panel.implicitHeight + 20
        onVisibleChanged: NetworkService.openPanels += visible ? 1 : -1
        Component.onDestruction: if (visible) NetworkService.openPanels--
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.colorBackground
            border.color: Theme.colorAccent
        }
        NetworkPanel {
            id: panel
            active: popup.visible
            width: implicitWidth
            height: implicitHeight
            anchors { top: parent.top; topMargin: 10; left: parent.left; leftMargin: 12 }
            focus: true
            Keys.onEscapePressed: popup.visible = false
        }
    }
}
