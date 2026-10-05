import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

import "../services"
import "../config.js" as Config

Text {
    id: root

    // qmllint disable unresolved-type
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property var connected: {
        const list = [];
        if (powered) {
            for (const device of adapter.devices.values) {
                if (device.connected)
                    list.push(device);
            }
        }
        return list;
    }

    text: !powered ? "󰂲" : connected.length > 0 ? "󰂱" : ""
    color: Config.colors.text
    font.family: Config.bar.fontFamily
    font.pixelSize: Config.bar.fontSize

    Process {
        id: launcher

        command: ["alacritty", "--command", "bluetui"]
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
        text: !root.powered ? "Bluetooth off" : root.connected.length === 0 ? "No devices connected" : root.connected.map(d => d.name).join("\n")
    }
}
