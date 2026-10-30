pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "../services"

Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.ready && sink.audio !== null
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available && sink.audio.muted

    onSinkChanged: hideTimer.stop()
    onAvailableChanged: hideTimer.stop()

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Connections {
        target: root.available ? root.sink.audio : null
        function onVolumesChanged() { hideTimer.restart(); }
        function onMutedChanged() { hideTimer.restart(); }
    }

    Timer {
        id: hideTimer
        interval: 1500
    }

    Variants {
        model: Quickshell.screens

        // qmllint disable uncreatable-type
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.available && hideTimer.running
            anchors.bottom: true
            // QMargins fields are not exposed to qmllint.
            // qmllint disable missing-property
            margins { bottom: 84 }
            // qmllint enable missing-property
            implicitWidth: 344
            implicitHeight: 80
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                color: Theme.colorBackground
                border.color: Theme.colorAccent
                border.width: 2

                Text {
                    anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                    text: root.muted ? "󰖁" : root.volume <= 0 ? "󰕿" : root.volume < 0.5 ? "󰖀" : "󰕾"
                    color: Theme.colorText
                    font.family: Theme.barFontFamily
                    font.pixelSize: 28
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 176
                    height: 8
                    color: Theme.colorTextMuted

                    Rectangle {
                        width: parent.width * (root.muted ? 0 : Math.max(0, Math.min(1, root.volume)))
                        height: parent.height
                        color: Theme.colorAccent
                    }
                }

                Text {
                    anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                    text: Math.round(root.volume * 100) + "%"
                    color: Theme.colorText
                    font.family: Theme.barFontFamily
                    font.pixelSize: Theme.barFontSize
                }
            }
        }
    }
}
