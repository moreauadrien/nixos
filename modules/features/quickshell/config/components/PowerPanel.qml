import Quickshell.Io
import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: content.implicitHeight
    property int limit: 0
    property string error: ""

    function refresh() {
        if (!reader.running) reader.running = true;
    }

    function setLimit(value) {
        if (writer.running) return;
        error = "";
        writer.command = ["sudo", "-n", "/run/current-system/sw/bin/charge-limit", String(value)];
        writer.running = true;
    }

    Process {
        id: reader
        command: ["charge-limit", "get"]
        stdout: StdioCollector { id: output }
        onExited: code => {
            root.limit = code === 0 ? Number(output.text.trim()) : 0;
            root.error = code === 0 ? "" : "Limite de charge indisponible";
        }
    }
    Process {
        id: writer
        onExited: code => {
            if (code !== 0) root.error = "Impossible de modifier la limite de charge";
            else root.refresh();
        }
    }

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
                    text: "󰐥"
                    color: Theme.colorAccent
                    font.family: Theme.barFontFamily
                    font.pixelSize: 24
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: "Power"
                        color: Theme.colorAccent
                        font.family: Theme.barFontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: "SYSTEM CONTROLS"
                        color: Theme.colorTextSubtle
                        font.family: Theme.barFontFamily
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }
        Text {
            text: "ALIMENTATION"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }
        Repeater {
            model: [
                { icon: "󰐥", title: "Éteindre", action: "poweroff" },
                { icon: "󰜉", title: "Redémarrer", action: "reboot" }
            ]
            delegate: Rectangle {
                required property var modelData
                width: content.width
                height: 48
                radius: 4
                color: actionMouse.containsMouse ? Qt.alpha(Theme.colorText, 0.08) : "transparent"
                border.width: actionMouse.containsMouse ? 1 : 0
                border.color: Theme.colorTextMuted
                Row {
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 10
                    Text {
                        text: modelData.icon
                        color: Theme.colorAccent
                        font.family: Theme.barFontFamily
                        font.pixelSize: 16
                    }
                    Text {
                        text: modelData.title
                        color: Theme.colorText
                        font.family: Theme.barFontFamily
                        font.pixelSize: 14
                    }
                }
                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerAction.command = ["systemctl", modelData.action];
                        powerAction.running = true;
                    }
                }
            }
        }
        Process { id: powerAction }

        Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }
        Text {
            text: "LIMITE DE CHARGE"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }
        Text {
            text: "Jusqu'au prochain redémarrage (80 % par défaut)"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
        }
        Row {
            spacing: 8
            Repeater {
                model: [80, 100]
                delegate: Rectangle {
                    required property int modelData
                    width: (content.width - 8) / 2
                    height: 40
                    radius: 4
                    color: root.limit === modelData ? Qt.alpha(Theme.colorAccent, 0.18)
                        : limitMouse.containsMouse ? Qt.alpha(Theme.colorText, 0.08) : "transparent"
                    border.width: 1
                    border.color: root.limit === modelData ? Theme.colorAccent : Theme.colorTextMuted
                    Text {
                        anchors.centerIn: parent
                        text: modelData + " %"
                        color: root.limit === modelData ? Theme.colorAccent : Theme.colorText
                        font.family: Theme.barFontFamily
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: limitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.limit !== 0 && !writer.running
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.setLimit(modelData)
                    }
                }
            }
        }
        Text {
            visible: root.error !== ""
            text: root.error
            color: Theme.colorError
            font.family: Theme.barFontFamily
            font.pixelSize: 11
        }
    }
}
