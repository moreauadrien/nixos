import Quickshell
import Quickshell.Io
import QtQuick
import "../components"
import "../services"

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

            implicitHeight: Theme.barHeight
            color: Theme.background

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
