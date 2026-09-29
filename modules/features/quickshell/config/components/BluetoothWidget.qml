import QtQuick
import Quickshell.Bluetooth

import "../services"

Text {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property int connectedCount: {
        if (!powered)
            return 0;
        const list = Bluetooth.devices ? Bluetooth.devices.values : [];
        let n = 0;
        for (const d of list)
            if (d && d.connected)
                n += 1;
        return n;
    }

    text: !powered ? "󰂲" : connectedCount > 0 ? "󰂱" : "󰂯"
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    Popup {
        id: bluetoothPopup

        anchorItem: root
        contentWidth: panel.implicitWidth
        contentHeight: panel.implicitHeight

        BluetoothPanel {
            id: panel

            popupVisible: bluetoothPopup.visible
            anchors.left: parent.left
            anchors.top: parent.top
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        cursorShape: Qt.PointingHandCursor
        onClicked: bluetoothPopup.open()
    }
}