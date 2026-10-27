import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../services"

Scope {
    id: root
    property bool centerOpen: false

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }
            margins {
                top: Theme.barHeight + 12
                right: 12
            }

            implicitWidth: 424
            implicitHeight: Math.max(1, column.implicitHeight)
            color: "transparent"

            exclusionMode: ExclusionMode.Ignore

            ColumnLayout {
                id: column
                width: parent.width
                spacing: 10

                Repeater {
                    model: server.trackedNotifications

                    delegate: Rectangle {
                        id: card
                        required property var modelData

                        Timer {
                            running: card.modelData.urgency !== NotificationUrgency.Critical
                            interval: 5000
                            onTriggered: card.modelData.dismiss()
                        }

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(60, layout.implicitHeight + 20)
                        radius: 8
                        color: Theme.colorBackground
                        border.width: 1
                        border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.colorError : Theme.colorAccent

                        RowLayout {
                            id: layout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Image {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignTop
                                fillMode: Image.PreserveAspectFit
                                visible: source.toString() !== ""
                                source: card.modelData.image || card.modelData.appIcon || ""
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.summary
                                    color: modelData.urgency === NotificationUrgency.Critical ? Theme.colorError : Theme.colorAccent
                                    font.family: Theme.barFontFamily
                                    font.pixelSize: 18
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: card.modelData.body
                                    color: Theme.colorText
                                    font.family: Theme.barFontFamily
                                    font.pixelSize: 14
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: card.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
