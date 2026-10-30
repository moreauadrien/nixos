pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: Math.min(500, content.implicitHeight)
    property var passwordNetwork: null
    property bool active: true

    function cancelPassword() {
        password.clear();
        password.echoMode = TextInput.Password;
        passwordNetwork = null;
    }
    function requestPassword(network) {
        cancelPassword();
        passwordNetwork = network;
        viewport.contentY = 0;
        password.forceActiveFocus();
    }
    function submitPassword() {
        if (!passwordNetwork || NetworkService.busy || !password.text) return;
        NetworkService.connect(passwordNetwork, password.text);
        password.clear();
        password.echoMode = TextInput.Password;
    }
    onActiveChanged: if (!active) cancelPassword()
    onVisibleChanged: if (!visible) cancelPassword()
    Connections {
        target: NetworkService
        function onWifiEnabledChanged() { if (!NetworkService.wifiEnabled) root.cancelPassword(); }
        function onConnectionFinished(network, success) {
            if (!root.active || !root.visible) return;
            if (success) root.cancelPassword();
            else if (network.security) root.requestPassword(network);
        }
    }

    component Label: Text {
        textFormat: Text.PlainText
        color: Theme.colorTextSubtle
        font.family: Theme.barFontFamily
        font.pixelSize: 11
    }
    component IconAction: AbstractButton {
        id: button
        required property string glyph
        width: 24
        height: 24
        background: Rectangle {
            radius: 4
            color: button.hovered ? Qt.alpha(Theme.colorText, 0.08) : "transparent"
            border.width: button.activeFocus ? 1 : 0
            border.color: Theme.colorAccent
        }
        contentItem: Label {
            text: button.glyph
            color: button.enabled ? Theme.colorTextSubtle : Theme.colorTextMuted
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Flickable {
        id: viewport
        anchors.fill: parent
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: content
            width: root.width
            spacing: 12

            PanelHeader {
                width: parent.width
                icon: NetworkService.icon
                title: "Network"
                subtitle: NetworkService.status
                actions: PanelSwitch {
                    objectName: "wifiSwitch"
                    active: NetworkService.wifiEnabled
                    enabled: NetworkService.available && !NetworkService.busy
                    Accessible.name: "Wi-Fi power"
                    onToggleRequested: NetworkService.run({action: "wifi", enabled: !NetworkService.wifiEnabled})
                }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }

            Column {
                width: parent.width
                spacing: 4
                visible: NetworkService.ethernet.length > 0
                Label { text: "ETHERNET"; font.letterSpacing: 1.5 }
                Repeater {
                    model: NetworkService.ethernet
                    delegate: PanelRow {
                        required property var modelData
                        width: content.width
                        glyph: "󰈀"
                        title: modelData.connection || modelData.interface
                        subtitle: selected ? "Connected" : "Disconnected"
                        selected: !!modelData.uuid
                        enabled: NetworkService.available && !NetworkService.busy
                        onClicked: {
                            if (selected) NetworkService.disconnect(modelData.interface);
                            else NetworkService.run({action: "wired", interface: modelData.interface});
                        }
                    }
                }
            }

            Row {
                width: parent.width
                Label {
                    width: parent.width - 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WI-FI"
                    font.letterSpacing: 1.5
                }
                IconAction {
                    glyph: "󰑐"
                    Accessible.name: "Scan Wi-Fi networks"
                    enabled: NetworkService.available && NetworkService.wifiEnabled && !NetworkService.busy
                    onClicked: NetworkService.scan()
                }
            }

            Column {
                width: parent.width
                visible: root.passwordNetwork !== null
                spacing: 6
                Label {
                    width: parent.width
                    text: "Password for " + (root.passwordNetwork ? root.passwordNetwork.ssid : "")
                    elide: Text.ElideRight
                }
                TextField {
                    id: password
                    objectName: "networkPassword"
                    width: parent.width
                    height: 34
                    rightPadding: 84
                    font.family: Theme.barFontFamily
                    font.pixelSize: echoMode === TextInput.Password && text.length > 0 ? 18 : 13
                    font.letterSpacing: echoMode === TextInput.Password && text.length > 0 ? 4 : 0
                    passwordCharacter: "●"
                    passwordMaskDelay: 0
                    color: Theme.colorText
                    placeholderText: NetworkService.connectingNetwork ? "Connecting…" : "Password · Enter to connect"
                    placeholderTextColor: Theme.colorTextSubtle
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    selectByMouse: true
                    enabled: !NetworkService.busy
                    Accessible.name: "Wi-Fi password"
                    background: Rectangle {
                        radius: 4
                        color: "transparent"
                        border.color: password.activeFocus ? Theme.colorAccent : Theme.colorTextMuted
                    }
                    onAccepted: root.submitPassword()
                    Keys.onEscapePressed: root.cancelPassword()
                    Row {
                        anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                        IconAction {
                            glyph: password.echoMode === TextInput.Password ? "󰈈" : "󰈉"
                            Accessible.name: "Show or hide password"
                            onClicked: password.echoMode = password.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password
                        }
                        IconAction {
                            glyph: "󰄬"
                            enabled: password.text.length > 0
                            Accessible.name: "Connect to Wi-Fi"
                            onClicked: root.submitPassword()
                        }
                        IconAction {
                            glyph: "󰅖"
                            Accessible.name: "Cancel"
                            onClicked: root.cancelPassword()
                        }
                    }
                }
            }

            Row {
                width: parent.width
                visible: NetworkService.connectionMessage !== ""
                spacing: 8
                BusyIndicator {
                    width: 20
                    height: 20
                    visible: NetworkService.connectingNetwork !== null
                    running: visible
                    palette.dark: Theme.colorAccent
                }
                Label {
                    objectName: "connectionFeedback"
                    width: parent.width - (NetworkService.connectingNetwork ? 28 : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    text: NetworkService.connectionMessage
                    color: NetworkService.error ? Theme.colorError : Theme.colorAccent
                    wrapMode: Text.Wrap
                    Accessible.role: Accessible.AlertMessage
                }
            }

            Column {
                width: parent.width
                spacing: 4
                Repeater {
                    model: NetworkService.wifiEnabled ? NetworkService.networks : []
                    delegate: PanelRow {
                        id: networkRow
                        required property var modelData
                        width: content.width
                        glyph: selected ? "󰤨" : "󰤥"
                        title: modelData.ssid
                        subtitle: NetworkService.connectingNetwork && NetworkService.connectingNetwork.bssid === modelData.bssid
                            ? "Connecting…" : selected ? "Connected" : modelData.known ? "Saved" : ""
                        detail: (modelData.security ? "  " : "") + modelData.signal + "%"
                        selected: !!modelData.active
                        enabled: NetworkService.available && !NetworkService.busy
                        onClicked: {
                            root.cancelPassword();
                            if (selected) NetworkService.disconnect(modelData.interface);
                            else if (modelData.security && !modelData.known) root.requestPassword(modelData);
                            else NetworkService.connect(modelData);
                        }
                        actions: IconAction {
                            visible: !!networkRow.modelData.known
                            glyph: "󰅖"
                            Accessible.name: "Forget " + networkRow.title
                            onClicked: {
                                root.cancelPassword();
                                NetworkService.forget(networkRow.modelData.uuid);
                            }
                        }
                        onPressAndHold: if (modelData.security && !selected) root.requestPassword(modelData)
                    }
                }
                Label {
                    visible: !NetworkService.wifiEnabled || NetworkService.networks.length === 0
                    text: NetworkService.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                    font.pixelSize: 13
                }
            }
            Label {
                width: parent.width
                visible: text !== ""
                objectName: "networkError"
                text: [NetworkService.connectionMessage ? "" : NetworkService.error,
                    NetworkService.statusError].filter(Boolean).join("\n")
                color: Theme.colorError
                wrapMode: Text.Wrap
                Accessible.role: Accessible.AlertMessage
            }
        }
    }
}
