pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: Math.min(550, content.implicitHeight)

    component Label: Text {
        color: Theme.colorText
        font.family: Theme.barFontFamily
        font.pixelSize: 13
        elide: Text.ElideRight
    }

    component Action: Button {
        id: button
        font.family: Theme.barFontFamily
        font.pixelSize: 12
        palette.buttonText: Theme.colorText
        contentItem: Label {
            text: button.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: button.enabled ? 1 : 0.4
        }
        background: Rectangle {
            radius: 4
            color: button.hovered ? Qt.alpha(Theme.colorAccent, 0.2) : Qt.alpha(Theme.colorText, 0.06)
            border.color: button.activeFocus ? Theme.colorAccent : Theme.colorTextMuted
        }
        Accessible.name: text
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
                TailscaleIcon {
                    iconSize: 24
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    color: TailscaleService.connected ? Theme.colorAccent : Theme.colorTextSubtle
                    crossed: TailscaleService.available && !TailscaleService.connected
                        && TailscaleService.data.BackendState !== "NeedsLogin"
                }
                Column {
                    x: 36
                    width: parent.width - x - 56
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Label {
                        width: parent.width
                        text: TailscaleService.hostname
                        color: Theme.colorAccent
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Label {
                        width: parent.width
                        text: TailscaleService.status
                        color: Theme.colorTextSubtle
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                }
                Switch {
                    id: connectionSwitch
                    objectName: "tailscaleSwitch"
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    padding: 0
                    spacing: 0
                    checked: TailscaleService.connected
                    enabled: TailscaleService.available && !TailscaleService.busy
                    Accessible.name: "Tailscale connection"
                    onToggled: TailscaleService.toggle()
                    indicator: Rectangle {
                        implicitWidth: 44
                        implicitHeight: 24
                        radius: 12
                        opacity: connectionSwitch.enabled ? 1 : 0.4
                        color: TailscaleService.connected ? Theme.colorAccent : Theme.colorTextSubtle
                        border.width: connectionSwitch.activeFocus ? 1 : 0
                        border.color: Theme.colorText
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            x: TailscaleService.connected ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.colorText
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }

            Action {
                visible: TailscaleService.authUrl !== ""
                width: parent.width
                text: "Log in in browser"
                onClicked: Qt.openUrlExternally(TailscaleService.authUrl)
            }

            Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }

            Column {
                visible: TailscaleService.connected
                width: parent.width
                spacing: 8
                Label {
                    text: "EXIT NODE"
                    color: Theme.colorTextSubtle
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                }
                ComboBox {
                    id: exitPicker
                    width: parent.width
                    enabled: !TailscaleService.busy
                    model: [{ ID: "", label: "None — direct connection" }].concat(
                        TailscaleService.exitNodes.map(peer => ({ ID: peer.ID,
                            label: TailscaleService.name(peer) + (peer.Online ? "" : " (offline)") })))
                    textRole: "label"
                    valueRole: "ID"
                    currentIndex: Math.max(0, model.findIndex(row => row.ID === TailscaleService.exitId))
                    font.family: Theme.barFontFamily
                    font.pixelSize: 13
                    palette.button: Theme.colorBackground
                    palette.base: Theme.colorBackground
                    palette.text: Theme.colorText
                    palette.buttonText: Theme.colorText
                    palette.highlight: Theme.colorAccent
                    palette.highlightedText: Theme.colorBackground
                    Accessible.name: "Exit node"
                    delegate: ItemDelegate {
                        required property var modelData
                        width: exitPicker.width
                        text: modelData.label
                        enabled: !modelData.ID || !!TailscaleService.exitNodes.find(peer => peer.ID === modelData.ID && peer.Online)
                        highlighted: exitPicker.currentValue === modelData.ID
                    }
                    onActivated: index => TailscaleService.selectExit(model[index].ID)
                }
                Label {
                    visible: TailscaleService.exitId !== ""
                    width: parent.width
                    text: "Internet traffic is routed through the selected node."
                    font.pixelSize: 11
                    color: Theme.colorTextSubtle
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
            }

            Column {
                visible: TailscaleService.connected
                width: parent.width
                spacing: 6
                Label {
                    text: "MACHINES · CLICK TO COPY IP"
                    color: Theme.colorTextSubtle
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }
                Repeater {
                    model: TailscaleService.connected ? (TailscaleService.data.Self ? [TailscaleService.data.Self] : []).concat(TailscaleService.peers) : []
                    delegate: Action {
                        id: machine
                        required property var modelData
                        width: content.width
                        height: 50
                        enabled: TailscaleService.ip(modelData) !== ""
                        Accessible.name: "Copy IP of " + TailscaleService.name(modelData)
                        contentItem: Column {
                            spacing: 4
                            Label {
                                width: parent.width
                                text: (machine.modelData.Online ? "●  " : "○  ") + TailscaleService.name(machine.modelData)
                                    + (machine.modelData.ID === (TailscaleService.data.Self || {}).ID ? " (this device)" : "")
                                color: machine.modelData.Online ? Theme.colorText : Theme.colorTextSubtle
                            }
                            Label {
                                width: parent.width
                                text: TailscaleService.ip(machine.modelData) + " · " + (machine.modelData.DNSName || "").replace(/\.$/, "")
                                color: Theme.colorTextSubtle
                                font.pixelSize: 10
                            }
                        }
                        onClicked: {
                            TailscaleService.copyIp(modelData);
                            copied.text = "Copied " + TailscaleService.ip(modelData);
                            copyTimer.restart();
                        }
                    }
                }
            }

            Label {
                id: copied
                visible: copyTimer.running
                color: Theme.colorAccent
                Timer { id: copyTimer; interval: 2000 }
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: TailscaleService.error || TailscaleService.statusError
                color: Theme.colorError
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: (TailscaleService.data.Health || []).join("\n")
                color: Theme.colorTextSubtle
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                font.pixelSize: 11
            }
        }
    }
}
