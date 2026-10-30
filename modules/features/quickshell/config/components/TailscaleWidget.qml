import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

Text {
    id: root
    text: "󰖂"
    color: TailscaleService.connected ? Theme.colorAccent : Theme.colorTextSubtle
    font.family: Theme.barFontFamily
    font.pixelSize: Theme.barFontSize

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) TailscaleService.toggle();
            else {
                if (!root.QsWindow.window) return;
                const right = root.mapToItem(null, root.width, 0).x;
                popup.margins.right = Math.max(8, root.QsWindow.window.screen.width - right);
                popup.visible = !popup.visible;
            }
        }
    }

    Tooltip {
        anchorItem: root
        screen: root.QsWindow.window ? root.QsWindow.window.screen : null
        text: "Tailscale · " + TailscaleService.status
        wantShow: mouse.containsMouse && !popup.visible
    }

    PanelWindow {
        visible: popup.visible
        screen: root.QsWindow.window ? root.QsWindow.window.screen : null
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea {
            anchors.fill: parent
            onPressed: popup.visible = false
        }
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
        onVisibleChanged: TailscaleService.openPanels += visible ? 1 : -1
        Component.onDestruction: if (visible) TailscaleService.openPanels--

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.colorBackground
            border.color: Theme.colorAccent
            border.width: 1
        }
        TailscalePanel {
            id: panel
            width: implicitWidth
            height: implicitHeight
            anchors { top: parent.top; topMargin: 10; left: parent.left; leftMargin: 12 }
            focus: true
            Keys.onEscapePressed: popup.visible = false
        }
    }
}
