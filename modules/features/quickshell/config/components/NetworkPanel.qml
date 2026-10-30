pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: Math.min(500, content.implicitHeight)
    property var passwordNetwork: null
    property Item passwordHost: null
    property bool active: true

    function syncPasswordHost() {
        passwordHost = null;
        if (!passwordNetwork) return;
        for (let i = 0; i < networkRows.count; i++) {
            const row = networkRows.itemAt(i);
            if (row && row.modelData.ssid === passwordNetwork.ssid
                && row.modelData.interface === passwordNetwork.interface) {
                passwordHost = row.editorSlot;
                return;
            }
        }
    }
    function cancelPassword() {
        password.clear();
        password.echoMode = TextInput.Password;
        passwordNetwork = null;
    }
    function requestPassword(network) {
        cancelPassword();
        passwordNetwork = network;
        Qt.callLater(() => {
            if (!root.active || !root.passwordHost) return;
            const bottom = editor.mapToItem(content, 0, editor.height).y;
            if (bottom > viewport.contentY + viewport.height)
                viewport.contentY = Math.min(bottom - viewport.height, Math.max(0, viewport.contentHeight - viewport.height));
            if (!NetworkService.busy) password.forceActiveFocus();
        });
    }
    function submitPassword() {
        if (!passwordNetwork || NetworkService.busy || !password.text) return;
        NetworkService.connect(passwordNetwork, password.text);
        password.clear();
        password.echoMode = TextInput.Password;
    }
    onPasswordNetworkChanged: syncPasswordHost()
    onActiveChanged: if (!active && !NetworkService.connectingNetwork) cancelPassword()
    onVisibleChanged: if (!visible && !NetworkService.connectingNetwork) cancelPassword()
    Connections {
        target: NetworkService
        function onWifiEnabledChanged() { if (!NetworkService.wifiEnabled) root.cancelPassword(); }
        function onConnectionFinished(network, success) {
            if (success) root.cancelPassword();
            else root.requestPassword(network);
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

    // Keep one editor alive across scan results, moving it beneath the selected row.
    Column {
        id: editor
        parent: root.passwordHost || root
        x: 10
        width: root.width - 20
        visible: root.passwordNetwork !== null && root.passwordHost !== null
        spacing: 6
        TextField {
            id: password
            objectName: "networkPassword"
            readonly property bool connecting: root.passwordNetwork !== null
                && NetworkService.connectingNetwork !== null
                && root.passwordNetwork.interface === NetworkService.connectingNetwork.interface
                && root.passwordNetwork.ssid === NetworkService.connectingNetwork.ssid
            visible: connecting || !!(root.passwordNetwork && root.passwordNetwork.security)
            width: parent.width
            height: 34
            leftPadding: 8
            rightPadding: connecting ? leftPadding : 84
            horizontalAlignment: connecting ? TextInput.AlignHCenter : TextInput.AlignLeft
            font.family: Theme.barFontFamily
            font.pixelSize: echoMode === TextInput.Password && text.length > 0 ? 18 : 13
            font.letterSpacing: echoMode === TextInput.Password && text.length > 0 ? 4 : 0
            passwordCharacter: "●"
            passwordMaskDelay: 0
            color: Theme.colorText
            placeholderText: connecting ? "Connecting…" : "Password · Enter to connect"
            placeholderTextColor: connecting ? Theme.colorAccent : Theme.colorTextSubtle
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            selectByMouse: true
            enabled: !NetworkService.busy
            Accessible.name: connecting ? "Connecting to " + root.passwordNetwork.ssid : "Wi-Fi password"
            background: Rectangle {
                radius: 4
                color: "transparent"
                border.color: password.activeFocus || password.connecting ? Theme.colorAccent : Theme.colorTextMuted
            }
            onAccepted: root.submitPassword()
            Keys.onEscapePressed: root.cancelPassword()
            Row {
                objectName: "passwordActions"
                visible: !password.connecting
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
        Label {
            objectName: "connectionFeedback"
            width: parent.width
            visible: NetworkService.connectionMessage !== "" && !password.connecting
            text: NetworkService.connectionMessage
            color: NetworkService.error ? Theme.colorError : Theme.colorAccent
            wrapMode: Text.Wrap
            Accessible.role: Accessible.AlertMessage
        }
    }

    Flickable {
        id: viewport
        objectName: "networkViewport"
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
                spacing: 4
                Repeater {
                    id: networkRows
                    model: NetworkService.wifiEnabled ? NetworkService.networks : []
                    onItemAdded: root.syncPasswordHost()
                    onItemRemoved: (index, item) => {
                        if (root.passwordHost === item.editorSlot) root.passwordHost = null;
                    }
                    delegate: Column {
                        id: entry
                        required property var modelData
                        property alias editorSlot: slot
                        width: content.width
                        spacing: 4
                        PanelRow {
                            id: networkRow
                            width: parent.width
                            glyph: selected ? "󰤨" : "󰤥"
                            title: entry.modelData.ssid
                            subtitle: selected ? "Connected" : entry.modelData.known ? "Saved" : ""
                            detail: (entry.modelData.security ? "  " : "") + entry.modelData.signal + "%"
                            selected: !!entry.modelData.active
                            enabled: NetworkService.available && !NetworkService.busy
                            onClicked: {
                                root.cancelPassword();
                                if (selected) NetworkService.disconnect(entry.modelData.interface);
                                else {
                                    root.requestPassword(entry.modelData);
                                    if (!entry.modelData.security || entry.modelData.known)
                                        NetworkService.connect(entry.modelData);
                                }
                            }
                            actions: IconAction {
                                visible: !!entry.modelData.known
                                glyph: "󰅖"
                                Accessible.name: "Forget " + networkRow.title
                                onClicked: {
                                    root.cancelPassword();
                                    NetworkService.forget(entry.modelData.uuid);
                                }
                            }
                            onPressAndHold: if (entry.modelData.security && !selected) root.requestPassword(entry.modelData)
                        }
                        Item {
                            id: slot
                            width: parent.width
                            visible: root.passwordHost === slot
                            height: visible ? editor.implicitHeight + 4 : 0
                        }
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
                text: [root.passwordHost ? "" : NetworkService.error,
                    NetworkService.statusError].filter(Boolean).join("\n")
                color: Theme.colorError
                wrapMode: Text.Wrap
                Accessible.role: Accessible.AlertMessage
            }
        }
    }
}
