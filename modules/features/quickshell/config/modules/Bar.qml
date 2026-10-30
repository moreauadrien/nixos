pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"
import "../services"

Scope {
    id: root
    property bool stayAwake: false

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
                    right: clock.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                height: Theme.barHeight
                verticalAlignment: Text.AlignVCenter
                text: ""
                font.family: Theme.barFontFamily
                font.pixelSize: Theme.barSmallIconSize
                color: root.stayAwake ? "#ffffff" : Theme.colorTextSubtle
                opacity: root.stayAwake || extraIconsHover.hovered ? 1 : 0

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
