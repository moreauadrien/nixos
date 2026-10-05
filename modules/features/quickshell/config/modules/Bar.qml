import Quickshell
import Quickshell.Io
import QtQuick
import "../components"
import "../services"
import "../config.js" as Config

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Config.bar.height
            color: Config.colors.background

            WorkspaceIndicator {
                anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }

            ClockWidget {
                anchors.centerIn: parent
            }

            Row {
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 12

                BluetoothWidget {}
                PowerWidget {}
            }
        }
    }
}
