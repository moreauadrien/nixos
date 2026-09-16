import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
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
    color: capacity <= 10 ? Theme.urgent : Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    Process {
        id: launcher

        command: ["powermenu"]
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: tooltip.wantShow = containsMouse
        onClicked: launcher.running = true
    }

    Tooltip {
        id: tooltip
        anchorItem: root
        text: root.tip
    }
}
