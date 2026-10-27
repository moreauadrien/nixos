import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: Math.min(500, content.implicitHeight)
    property string hoveredVolumeAddress: ""

    Keys.onPressed: event => {
        const address = root.hoveredVolumeAddress;
        const volume = BluetoothAudio.volumes[address];
        if (!BluetoothAudio.combined.includes(address) || volume === undefined) return;
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down)
            BluetoothAudio.setVolume(address, volume - 5);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up)
            BluetoothAudio.setVolume(address, volume + 5);
        else return;
        event.accepted = true;
    }

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: root.width
            spacing: 12

            Item {
                width: parent.width
                height: 54
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Text {
                        text: "󰂯"
                        color: Theme.colorAccent
                        font.family: Theme.barFontFamily
                        font.pixelSize: 24
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Bluetooth"
                            color: Theme.colorAccent
                            font.family: Theme.barFontFamily
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            text: BluetoothService.status
                            color: Theme.colorTextSubtle
                            font.family: Theme.barFontFamily
                            font.pixelSize: 11
                            font.letterSpacing: 1
                        }
                    }
                }
                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    visible: BluetoothService.adapter !== null
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    color: BluetoothService.powered ? Theme.colorAccent : Theme.colorTextSubtle
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        x: BluetoothService.powered ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.colorText
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.togglePower()
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }

            Repeater {
                model: BluetoothService.sections
                delegate: Column {
                    required property var modelData
                    width: content.width
                    spacing: 6
                    visible: modelData.rows.length > 0
                    height: visible ? implicitHeight : 0
                    Text {
                        text: modelData.title
                        color: Theme.colorTextSubtle
                        font.family: Theme.barFontFamily
                        font.pixelSize: 11
                        font.letterSpacing: 1.5
                    }
                    Repeater {
                        model: modelData.rows
                        delegate: Rectangle {
                            id: deviceRow
                            required property var modelData
                            width: content.width
                            height: 48
                            radius: 4
                            color: rowHover.hovered ? Qt.alpha(Theme.colorText, 0.08) : "transparent"
                            border.width: rowHover.hovered ? 1 : 0
                            border.color: Theme.colorTextMuted

                            HoverHandler {
                                id: rowHover
                                onHoveredChanged: {
                                    if (hovered && volumeSlider.visible) {
                                        root.hoveredVolumeAddress = volumeSlider.address;
                                        root.forceActiveFocus();
                                    } else if (root.hoveredVolumeAddress === volumeSlider.address) {
                                        root.hoveredVolumeAddress = "";
                                    }
                                }
                            }

                            // The background area is declared before the action button so it cannot steal clicks.
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothService.activate(modelData.address)
                            }
                            Row {
                                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                spacing: 10
                                Text {
                                    text: modelData.connected ? "󰂱" : "󰂯"
                                    color: modelData.connected ? Theme.colorAccent : Theme.colorTextSubtle
                                    font.family: Theme.barFontFamily
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item {
                                    width: 285
                                    height: deviceRow.height
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        id: deviceName
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: BluetoothAudio.combined.includes(modelData.address.toUpperCase()) ? 160 : parent.width
                                        text: modelData.name
                                        color: Theme.colorText
                                        font.family: Theme.barFontFamily
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.top: deviceName.bottom
                                        text: modelData.pending || (modelData.busy ? "Working…"
                                            : BluetoothAudio.selected === modelData.address.toUpperCase() ? "Select another output"
                                            : BluetoothAudio.combined.includes(modelData.address.toUpperCase()) ? "Combined audio"
                                            : rowMouse.containsMouse ? (modelData.connected ? "Disconnect"
                                                : modelData.known ? "Connect" : "Pair")
                                            : modelData.connected && modelData.battery >= 0 ? modelData.battery + "%" : "")
                                        color: Theme.colorAccent
                                        font.family: Theme.barFontFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }
                            Item {
                                id: volumeSlider
                                readonly property string address: modelData.address.toUpperCase()
                                visible: modelData.connected && BluetoothAudio.combined.includes(address)
                                width: 142
                                height: 28
                                anchors { right: parent.right; rightMargin: 66; verticalCenter: parent.verticalCenter }
                                Text {
                                    width: 34
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: BluetoothAudio.volumes[volumeSlider.address] === undefined ? "--" : Math.round(slider.value) + "%"
                                    color: Theme.colorAccent
                                    font.family: Theme.barFontFamily
                                    font.pixelSize: 11
                                }
                                VolumeSlider {
                                    id: slider
                                    x: 36
                                    width: parent.width - x
                                    height: parent.height
                                    value: BluetoothAudio.volumes[volumeSlider.address] ?? 0
                                    Accessible.name: "Volume de " + modelData.name
                                    onVolumeEdited: percent => BluetoothAudio.setVolume(volumeSlider.address, percent)
                                }
                            }
                            Rectangle {
                                visible: modelData.connected
                                width: 22
                                height: 22
                                radius: 11
                                anchors { right: parent.right; rightMargin: 38; verticalCenter: parent.verticalCenter }
                                color: mergeMouse.containsMouse ? Qt.alpha(Theme.colorAccent, 0.15) : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uE727"
                                    color: BluetoothAudio.selected === modelData.address.toUpperCase()
                                        || BluetoothAudio.combined.includes(modelData.address.toUpperCase())
                                        ? Theme.colorAccent : mergeMouse.containsMouse ? Theme.colorText : Theme.colorTextSubtle
                                    font.family: Theme.barFontFamily
                                    font.pixelSize: 16
                                }
                                MouseArea {
                                    id: mergeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: BluetoothAudio.toggle(modelData.address)
                                }
                            }
                            Rectangle {
                                visible: modelData.known
                                width: 22
                                height: 22
                                radius: 11
                                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                color: forgetMouse.containsMouse ? Qt.alpha(Theme.colorError, 0.2) : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: forgetMouse.containsMouse ? Theme.colorError : Theme.colorTextSubtle
                                    font.family: Theme.barFontFamily
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    id: forgetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: BluetoothService.forget(modelData.address)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: BluetoothAudio.error !== ""
                text: BluetoothAudio.error
                color: Theme.colorError
                font.family: Theme.barFontFamily
                font.pixelSize: 11
                width: parent.width
                wrapMode: Text.Wrap
            }

            Text {
                visible: !BluetoothService.hasDevices
                text: !BluetoothService.adapter ? "No Bluetooth adapter"
                    : !BluetoothService.powered ? "Turn Bluetooth on to scan" : "Scanning for devices…"
                color: Theme.colorTextSubtle
                font.family: Theme.barFontFamily
                font.pixelSize: 13
            }
        }
    }
}
