pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: Math.min(550, content.implicitHeight)

    component CopyOption: MenuItem {
        required property string label
        required property string value
        text: value || "Unavailable"
        Accessible.name: label + ": " + (value || "Unavailable")
        enabled: value !== ""
        font.family: Theme.barFontFamily
        font.pixelSize: 12
        onTriggered: {
            TailscaleService.copy(value);
            copied.text = "Copied " + value;
            copyTimer.restart();
        }
    }

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
                    color: TailscaleService.connected ? Theme.colorText : Theme.colorTextSubtle
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
                        objectName: "tailscaleHostname"
                        text: TailscaleService.hostname
                        color: Theme.colorAccent
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Label {
                        width: parent.width
                        // Reserve the status line so the hostname never moves during actions.
                        opacity: !TailscaleService.connected || TailscaleService.busy ? 1 : 0
                        Accessible.ignored: opacity === 0
                        text: TailscaleService.status
                        color: Theme.colorTextSubtle
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                }
                PanelSwitch {
                    objectName: "tailscaleSwitch"
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    active: TailscaleService.connected
                    enabled: TailscaleService.available && !TailscaleService.busy
                    Accessible.name: "Tailscale connection"
                    onToggleRequested: TailscaleService.toggle()
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
                    objectName: "exitNodePicker"
                    width: parent.width
                    implicitHeight: 32
                    leftPadding: 8
                    rightPadding: 28
                    contentItem: Label {
                        text: exitPicker.displayText
                        verticalAlignment: Text.AlignVCenter
                        color: TailscaleService.exitId ? Theme.colorText : Theme.colorTextSubtle
                        opacity: exitPicker.enabled ? 1 : 0.5
                    }
                    indicator: Label {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: "󰍝"
                        color: Theme.colorTextSubtle
                    }
                    background: Rectangle {
                        radius: 4
                        border.width: 0
                        color: exitPicker.hovered || exitPicker.activeFocus || exitPicker.popup.visible
                            ? Qt.alpha(Theme.colorText, 0.06) : "transparent"
                    }
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
                    palette.highlight: Theme.colorSurface
                    palette.highlightedText: Theme.colorText
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
                    text: "MACHINES"
                    color: Theme.colorTextSubtle
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }
                Repeater {
                    model: TailscaleService.connected ? (TailscaleService.data.Self ? [TailscaleService.data.Self] : []).concat(TailscaleService.peers) : []
                    delegate: Rectangle {
                        id: machine
                        required property var modelData
                        width: content.width
                        height: 50
                        radius: 4
                        color: "transparent"
                        Column {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            width: parent.width - 56
                            spacing: 4
                            Label {
                                width: parent.width
                                text: (machine.modelData.Online ? "●  " : "○  ") + TailscaleService.name(machine.modelData)
                                    + (machine.modelData.ID === (TailscaleService.data.Self || {}).ID ? " (this device)" : "")
                                color: machine.modelData.Online ? Theme.colorText : Theme.colorTextSubtle
                            }
                            Label {
                                width: parent.width
                                text: [TailscaleService.ip(machine.modelData), TailscaleService.domain(machine.modelData)].filter(Boolean).join(" · ")
                                color: Theme.colorTextSubtle
                                font.pixelSize: 10
                            }
                        }
                        Action {
                            id: copyButton
                            objectName: "copyMachine"
                            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                            width: 32
                            height: 32
                            text: ""
                            Accessible.name: "Copy address of " + TailscaleService.name(machine.modelData)
                            onClicked: copyMenu.open()

                            Menu {
                                id: copyMenu
                                x: copyButton.width - width
                                y: copyButton.height
                                width: 370
                                palette.window: Theme.colorBackground
                                palette.base: Theme.colorBackground
                                palette.text: Theme.colorText
                                palette.windowText: Theme.colorText
                                palette.highlight: Theme.colorSurface
                                palette.highlightedText: Theme.colorText
                                background: Rectangle {
                                    color: Theme.colorBackground
                                    border.color: Theme.colorTextMuted
                                    radius: 4
                                }
                                CopyOption { label: "Name"; value: TailscaleService.name(machine.modelData) }
                                CopyOption { label: "Domain"; value: TailscaleService.domain(machine.modelData) }
                                CopyOption { label: "IPv4"; value: TailscaleService.ip(machine.modelData) }
                                CopyOption { label: "IPv6"; value: TailscaleService.ip(machine.modelData, true) }
                            }
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
