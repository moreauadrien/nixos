import Quickshell.Io
import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: content.implicitHeight
    property int limit: 0
    property string error: ""
    property bool active: false
    property string cpuTemperature: "?"
    property string coolingProfile: ""
    property string coolingError: ""

    function refresh() {
        if (!reader.running) reader.running = true;
        if (!coolingReader.running) coolingReader.running = true;
    }

    function setCoolingProfile(mode) {
        if (coolingWriter.running) return;
        coolingError = "";
        coolingWriter.command = ["sudo", "-n", "/run/current-system/sw/bin/cooling-control", mode];
        coolingWriter.running = true;
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
            root.error = code === 0 ? "" : "Charge limit unavailable";
        }
    }
    Process {
        id: writer
        onExited: code => {
            if (code !== 0) root.error = "Unable to change charge limit";
            else root.refresh();
        }
    }

    Process {
        id: coolingReader
        command: ["cooling-control", "status"]
        stdout: StdioCollector { id: coolingOutput }
        onExited: code => {
            if (code !== 0) {
                root.coolingError = "Cooling profile unavailable";
                root.coolingProfile = "";
                root.cpuTemperature = "?";
                return;
            }
            if (root.coolingError === "Cooling profile unavailable") root.coolingError = "";
            const values = coolingOutput.text.trim().split(/\s+/);
            root.cpuTemperature = values[0] || "?";
            root.coolingProfile = values[1] || "";
        }
    }
    Process {
        id: coolingWriter
        onExited: code => {
            if (code !== 0) root.coolingError = "Unable to change cooling profile";
            else root.refresh();
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: root.active
        onTriggered: { if (!coolingReader.running) coolingReader.running = true; }
    }

    Column {
        id: content
        width: root.width
        spacing: 12

        PanelHeader {
            width: parent.width
            icon: "󰐥"
            title: "Power"
            subtitle: "SYSTEM CONTROLS"
        }

        Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }
        Text {
            text: "POWER"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }
        Repeater {
            model: [
                { icon: "󰐥", title: "Shut down", action: "poweroff" },
                { icon: "󰜉", title: "Restart", action: "reboot" }
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
            text: "COOLING"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }
        Text {
            text: "CPU: " + root.cpuTemperature + " °C"
            color: Theme.colorText
            font.family: Theme.barFontFamily
            font.pixelSize: 14
        }
        Text {
            text: "Firmware profiles"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
        }
        Row {
            spacing: 8
            Repeater {
                model: [
                    { name: "low-power", label: "Low power" },
                    { name: "quiet", label: "Quiet" },
                    { name: "balanced", label: "Balanced" },
                    { name: "performance", label: "Performance" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: (content.width - 24) / 4
                    height: 40
                    radius: 4
                    color: root.coolingProfile === modelData.name ? Qt.alpha(Theme.colorAccent, 0.18)
                        : coolingMouse.containsMouse ? Qt.alpha(Theme.colorText, 0.08) : "transparent"
                    border.width: 1
                    border.color: root.coolingProfile === modelData.name ? Theme.colorAccent : Theme.colorTextMuted
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.coolingProfile === modelData.name ? Theme.colorAccent : Theme.colorText
                        font.family: Theme.barFontFamily
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: coolingMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.coolingProfile !== "" && !coolingWriter.running
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.setCoolingProfile(modelData.name)
                    }
                }
            }
        }
        Text {
            visible: root.coolingError !== ""
            text: root.coolingError
            color: Theme.colorError
            font.family: Theme.barFontFamily
            font.pixelSize: 11
        }

        Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }
        Text {
            text: "CHARGE LIMIT"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }
        Text {
            text: "Until next reboot (80% by default)"
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
                        text: modelData + "%"
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
