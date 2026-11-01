pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../components"
import "../services"

Scope {
    id: root
    property bool stayAwake: false
    property bool nightMode: false
    property bool nightModeAvailable: false

    Process {
        id: nightModeReader
        command: ["hyprctl", "hyprsunset", "identity", "get"]
        stdout: StdioCollector { id: nightModeOutput }
        onExited: code => {
            const value = nightModeOutput.text.trim();
            root.nightModeAvailable = code === 0 && (value === "true" || value === "false");
            root.nightMode = root.nightModeAvailable && value === "false";
        }
    }

    Process {
        id: nightModeWriter
        onExited: code => {
            if (code !== 0) console.warn("Unable to change night mode");
            nightModeReader.running = true;
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!nightModeReader.running && !nightModeWriter.running)
                nightModeReader.running = true;
        }
    }

    Variants {
        model: Quickshell.screens

        // qmllint disable uncreatable-type
        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Theme.barHeight
            color: Theme.colorBackground

            WorkspaceIndicator {
                anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }

            Item {
                anchors {
                    right: clock.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: clock.x * Theme.barExtraIconsRevealFraction

                HoverHandler {
                    id: extraIconsHover
                }
            }

            IdleInhibitor {
                window: bar
                enabled: root.stayAwake
            }

            ClockWidget {
                id: clock
                anchors.centerIn: parent
            }

            Text {
                id: coffee
                anchors {
                    right: root.nightMode && !root.stayAwake ? moon.left : clock.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                height: Theme.barHeight
                verticalAlignment: Text.AlignVCenter
                text: ""
                font.family: Theme.barFontFamily
                font.pixelSize: Theme.barSmallIconSize
                color: root.stayAwake ? "#ffffff" : Theme.colorTextSubtle
                visible: root.stayAwake || extraIconsHover.hovered || coffeeMouse.containsMouse

                MouseArea {
                    id: coffeeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.stayAwake = !root.stayAwake
                }

                Tooltip {
                    anchorItem: coffee
                    screen: bar.screen
                    text: "Stay awake"
                    wantShow: coffeeMouse.containsMouse
                }
            }

            Text {
                id: moon
                anchors {
                    right: root.nightMode && !root.stayAwake ? clock.left : coffee.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                height: Theme.barHeight
                verticalAlignment: Text.AlignVCenter
                text: "󰔎"
                font.family: Theme.barFontFamily
                font.pixelSize: Theme.barSmallIconSize
                color: root.nightMode ? "#ffffff" : Theme.colorTextSubtle
                visible: root.nightMode || extraIconsHover.hovered || moonMouse.containsMouse

                MouseArea {
                    id: moonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.nightModeAvailable || nightModeReader.running || nightModeWriter.running) return;
                        nightModeWriter.command = root.nightMode
                            ? ["hyprctl", "hyprsunset", "identity"]
                            : ["hyprctl", "hyprsunset", "temperature", "4500"];
                        nightModeWriter.running = true;
                    }
                }

                Tooltip {
                    anchorItem: moon
                    screen: bar.screen
                    text: "Night mode"
                    wantShow: moonMouse.containsMouse
                }
            }

            Row {
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 12

                TailscaleWidget {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -1
                }
                NetworkWidget {}
                SoundWidget {}
                BluetoothWidget {}
                PowerWidget {}
            }
        }
    }
}
