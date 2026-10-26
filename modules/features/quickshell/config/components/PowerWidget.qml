import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import "../services"

Text {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property int capacity: Math.round(device.percentage * 100)
    readonly property int level: Math.min(9, Math.floor(capacity / 10))
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged

    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property var chargingIcons: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]

    readonly property int powerW: Math.round(device.energyRate)
    readonly property string tip: charging ? `${capacity}% ↑${powerW}W` : `${capacity}% ↓${powerW}W`

    text: full ? "󰂅" : charging ? chargingIcons[level] : icons[level]
    color: capacity <= 10 ? Theme.colorWarning : Theme.colorText
    font.family: Theme.barFontFamily
    font.pixelSize: Theme.barFontSize

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: tooltip.wantShow = containsMouse
        onClicked: {
            if (popup.visible) {
                popup.visible = false;
                return;
            }
            if (!root.QsWindow.window) return;
            const right = root.mapToItem(null, root.width, 0).x;
            popup.margins.right = Math.max(8, root.QsWindow.window.screen.width - right);
            panel.refresh();
            popup.visible = true;
        }
    }

    Tooltip {
        id: tooltip
        anchorItem: root
        text: root.tip
    }

    PanelWindow {
        visible: popup.visible
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
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors { top: true; right: true }
        margins.top: Theme.barHeight + 4
        margins.right: 8
        implicitWidth: 424
        implicitHeight: panel.implicitHeight + 20

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.colorBackground
            border.color: Theme.colorAccent
            border.width: 1
        }
        PowerPanel {
            id: panel
            anchors { top: parent.top; topMargin: 10; left: parent.left; leftMargin: 12 }
            focus: true
            Keys.onEscapePressed: popup.visible = false
        }
    }
}
