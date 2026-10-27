pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: content.implicitHeight
    property bool active: false

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
                        text: "󰕾"
                        color: Theme.colorAccent
                        font.family: Theme.barFontFamily
                        font.pixelSize: 24
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Son"
                            color: Theme.colorAccent
                            font.family: Theme.barFontFamily
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            text: "PÉRIPHÉRIQUES AUDIO"
                            color: Theme.colorTextSubtle
                            font.family: Theme.barFontFamily
                            font.pixelSize: 11
                            font.letterSpacing: 1
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }
            AudioSection { width: parent.width; output: false }
            Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }
            AudioSection { width: parent.width; output: true }
        }
    }

    component AudioSection: Column {
        id: section
        required property bool output
        readonly property PwNode node: output ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource
        readonly property bool available: node !== null && node.ready && node.audio !== null
        property var unavailable: ({})
        readonly property var devices: Pipewire.nodes.values.filter(n => n.audio !== null
            && !n.isStream && n.isSink === output && !unavailable[n.name])
        spacing: 4

        PwObjectTracker { objects: section.node ? [section.node] : [] }

        // Pipewire's QML API does not expose route availability; keep disconnected ports out of the list.
        Process {
            id: routes
            command: ["pactl", "--format=json", "list", section.output ? "sinks" : "sources"]
            stdout: StdioCollector { id: routeData }
            onExited: code => {
                if (code !== 0) return;
                try {
                    const hidden = {};
                    for (const device of JSON.parse(routeData.text)) {
                        const ports = device.ports || [];
                        if (ports.length && ports.every(port => port.availability === "not available"))
                            hidden[device.name] = true;
                    }
                    section.unavailable = hidden;
                } catch (error) {
                    console.warn("Cannot read audio routes:", error);
                }
            }
        }
        Timer {
            interval: 2000
            running: root.active
            repeat: true
            triggeredOnStart: true
            onTriggered: { if (!routes.running) routes.running = true; }
        }

        Text {
            text: section.output ? "SORTIE" : "ENTRÉE"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }

        Row {
            width: parent.width
            spacing: 10

            AbstractButton {
                id: muteButton
                width: 32
                height: 36
                enabled: section.available
                Accessible.name: section.output ? "Couper la sortie audio" : "Couper le microphone"
                checkable: true
                checked: section.available && section.node.audio.muted
                onClicked: section.node.audio.muted = !section.node.audio.muted
                background: Rectangle {
                    radius: 4
                    color: muteButton.hovered ? Qt.alpha(Theme.colorText, 0.08) : "transparent"
                    border.width: muteButton.activeFocus ? 1 : 0
                    border.color: Theme.colorAccent
                }
                contentItem: Text {
                    text: section.output ? (muteButton.checked ? "󰖁" : "󰕾") : (muteButton.checked ? "󰍭" : "󰍬")
                    color: muteButton.checked ? Theme.colorTextSubtle : Theme.colorAccent
                    font.family: Theme.barFontFamily
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            VolumeSlider {
                id: volume
                width: section.width - muteButton.width - percentage.width - 20
                height: 36
                enabled: section.available
                muted: section.available && section.node.audio.muted
                value: section.available ? section.node.audio.volume * 100 : 0
                Accessible.name: section.output ? "Volume de sortie" : "Volume d’entrée"
                onVolumeEdited: percent => {
                    if (section.available) section.node.audio.volume = percent / 100;
                }
            }

            Text {
                id: percentage
                width: 44
                height: 36
                text: section.available ? Math.round(section.node.audio.volume * 100) + " %" : "--"
                color: Theme.colorAccent
                font.family: Theme.barFontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        Repeater {
            model: section.devices
            delegate: AbstractButton {
                id: deviceButton
                required property PwNode modelData
                readonly property bool selected: section.node === modelData
                width: section.width
                height: 34
                Accessible.name: modelData.description || modelData.name
                onClicked: {
                    if (section.output) Pipewire.preferredDefaultAudioSink = modelData;
                    else Pipewire.preferredDefaultAudioSource = modelData;
                }
                background: Rectangle {
                    radius: 4
                    color: deviceButton.hovered ? Qt.alpha(Theme.colorText, 0.06) : "transparent"
                    border.width: deviceButton.activeFocus ? 1 : 0
                    border.color: Theme.colorAccent
                }
                contentItem: Item {
                    Text {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        text: deviceButton.selected ? "󰄬" : ""
                        color: deviceButton.selected ? Theme.colorAccent : Theme.colorTextSubtle
                        font.family: Theme.barFontFamily
                        font.pixelSize: 16
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 38; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: deviceButton.modelData.nickname || deviceButton.modelData.description || deviceButton.modelData.name
                        color: deviceButton.selected ? Theme.colorAccent : Theme.colorText
                        font.family: Theme.barFontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Text {
            visible: section.devices.length === 0
            text: section.output ? "Aucune sortie audio" : "Aucune entrée audio"
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 13
        }
    }
}
