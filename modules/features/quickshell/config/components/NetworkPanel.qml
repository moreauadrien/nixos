pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../services"

Item {
    id: root
    implicitWidth: 400
    implicitHeight: Math.min(620, content.implicitHeight)

    property var passwordNetwork: null
    readonly property string dnsProfile: NetworkService.active.uuid || ""
    property string dnsMode: "auto"
    readonly property string dnsConfiguration: dnsProfile + ":" + (NetworkService.active.dnsMode || "auto")
        + ":" + (NetworkService.active.dns || []).join(",")

    function cancelPassword() {
        password.clear();
        showPassword.checked = false;
        passwordNetwork = null;
    }

    function requestPassword(network) {
        cancelPassword();
        passwordNetwork = network;
        Qt.callLater(() => {
            if (!root.passwordNetwork)
                return;
            viewport.contentY = Math.max(0, Math.min(passwordEditor.y, content.implicitHeight - viewport.height));
            password.forceActiveFocus();
        });
    }

    function submitPassword() {
        if (!passwordNetwork || NetworkService.busy || !password.text)
            return;
        NetworkService.connect(passwordNetwork, password.text);
        cancelPassword();
    }

    onDnsConfigurationChanged: {
        dnsMode = NetworkService.active.dnsMode || "auto";
        if (customDns)
            customDns.text = dnsMode === "custom" ? (NetworkService.active.dns || []).join(", ") : "";
    }
    onVisibleChanged: { if (!visible) cancelPassword(); }
    Component.onDestruction: cancelPassword()

    Connections {
        target: NetworkService
        function onWifiEnabledChanged() {
            if (!NetworkService.wifiEnabled)
                root.cancelPassword();
        }
    }

    component Label: Text {
        color: Theme.colorText
        font.family: Theme.barFontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }

    component Heading: Label {
        font.pixelSize: 10
        font.letterSpacing: 1
        color: Theme.colorTextSubtle
    }

    component Action: Button {
        id: button
        implicitHeight: 28
        font.family: Theme.barFontFamily
        font.pixelSize: 11
        contentItem: Label {
            text: button.text
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: button.enabled ? 1 : 0.4
        }
        background: Rectangle {
            radius: 4
            color: button.hovered || button.checked ? Qt.alpha(Theme.colorAccent, 0.2) : Qt.alpha(Theme.colorText, 0.06)
            border.color: button.activeFocus ? Theme.colorAccent : Theme.colorTextMuted
        }
        Accessible.name: text
    }

    component Field: TextField {
        font.family: Theme.barFontFamily
        font.pixelSize: 12
        color: Theme.colorText
        placeholderTextColor: Theme.colorTextSubtle
        selectByMouse: true
        implicitHeight: 30
        background: Rectangle {
            radius: 4
            color: Qt.alpha(Theme.colorText, 0.06)
            border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorTextMuted
        }
    }

    component NetworkRow: Rectangle {
        id: networkRow
        required property var network
        width: content.width
        height: rowContent.implicitHeight + 16
        radius: 4
        color: network.active ? Qt.alpha(Theme.colorAccent, 0.15) : "transparent"

        Column {
            id: rowContent
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 6
            Row {
                width: parent.width
                spacing: 8
                Label {
                    width: 20
                    text: "󰤨"
                    color: networkRow.network.active ? Theme.colorAccent : Theme.colorTextSubtle
                }
                Label {
                    width: parent.width - 94
                    text: networkRow.network.ssid || "Hidden network"
                    color: networkRow.network.active ? Theme.colorAccent : Theme.colorText
                    Accessible.name: text + (networkRow.network.active ? ", connected" : "")
                }
                Label {
                    width: 58
                    horizontalAlignment: Text.AlignRight
                    text: (networkRow.network.security ? " " : "") + networkRow.network.signal + "%"
                    color: Theme.colorTextSubtle
                    font.pixelSize: 10
                }
            }
            Row {
                spacing: 6
                enabled: NetworkService.available && NetworkService.wifiEnabled && !NetworkService.busy
                Action {
                    text: networkRow.network.active ? "Disconnect" : "Connect"
                    Accessible.name: text + " " + (networkRow.network.ssid || "hidden network")
                    onClicked: {
                        root.cancelPassword();
                        if (networkRow.network.active)
                            NetworkService.disconnect(networkRow.network.interface);
                        else if (networkRow.network.security && !networkRow.network.known)
                            root.requestPassword(networkRow.network);
                        else
                            NetworkService.connect(networkRow.network);
                    }
                }
                Action {
                    visible: !!networkRow.network.security && !!networkRow.network.known && !networkRow.network.active
                    text: "Password…"
                    Accessible.name: "Retry with password for " + networkRow.network.ssid
                    onClicked: root.requestPassword(networkRow.network)
                }
                Action {
                    visible: !!networkRow.network.known && !!networkRow.network.uuid
                    text: "Forget"
                    Accessible.name: "Forget " + networkRow.network.ssid
                    onClicked: {
                        root.cancelPassword();
                        NetworkService.forget(networkRow.network.uuid);
                    }
                }
            }
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
            spacing: 10

            Item {
                width: parent.width
                height: 52
                Label {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: NetworkService.icon
                    font.pixelSize: 24
                    color: NetworkService.connected ? Theme.colorAccent : Theme.colorTextSubtle
                }
                Column {
                    x: 36
                    width: parent.width - x - 54
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Label {
                        width: parent.width
                        text: NetworkService.active.name || "Network"
                        color: Theme.colorAccent
                        font.pixelSize: 17
                        font.bold: true
                    }
                    Label {
                        width: parent.width
                        text: NetworkService.status
                        color: Theme.colorTextSubtle
                        font.pixelSize: 10
                    }
                }
                PanelSwitch {
                    objectName: "wifiSwitch"
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    active: NetworkService.wifiEnabled
                    enabled: NetworkService.available && !NetworkService.busy
                    Accessible.name: "Wi-Fi radio (does not affect wired connections)"
                    onToggleRequested: {
                        root.cancelPassword();
                        NetworkService.run({action: "wifi", enabled: !NetworkService.wifiEnabled});
                    }
                }
            }

            Label {
                width: parent.width
                text: NetworkService.wifiEnabled ? "Wi-Fi enabled" : "Wi-Fi disabled — wired connections are unaffected"
                color: Theme.colorTextSubtle
                font.pixelSize: 10
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }

            Repeater {
                model: (NetworkService.data.devices || []).filter(device => device.type === "ethernet")
                delegate: Row {
                    id: wired
                    required property var modelData
                    width: content.width
                    spacing: 8
                    Label {
                        width: parent.width - 104
                        text: "󰈀  " + wired.modelData.interface + " · "
                            + (wired.modelData.connection || wired.modelData.state || "Disconnected")
                        color: wired.modelData.uuid ? Theme.colorText : Theme.colorTextSubtle
                    }
                    Action {
                        width: 96
                        visible: !!wired.modelData.uuid
                        text: "Disconnect"
                        enabled: NetworkService.available && !NetworkService.busy
                        Accessible.name: "Disconnect wired interface " + wired.modelData.interface
                        onClicked: NetworkService.disconnect(wired.modelData.interface)
                    }
                }
            }

            Grid {
                visible: NetworkService.connected
                width: parent.width
                columns: 2
                columnSpacing: 12
                rowSpacing: 5
                Repeater {
                    model: [
                        ["Ping", NetworkService.pingMs < 0 ? "—" : NetworkService.pingMs.toFixed(0) + " ms"],
                        ["Packet loss", NetworkService.packetLoss < 0 ? "—" : NetworkService.packetLoss.toFixed(0) + "%"],
                        ["Receiving", NetworkService.formatBytes(NetworkService.rxRate) + "/s"],
                        ["Sending", NetworkService.formatBytes(NetworkService.txRate) + "/s"],
                        ["Downloaded", NetworkService.formatBytes(NetworkService.active.rxBytes || 0)],
                        ["Uploaded", NetworkService.formatBytes(NetworkService.active.txBytes || 0)],
                        ["IP address", NetworkService.active.ip || "—"],
                        ["Gateway", NetworkService.active.gateway || "—"]
                    ]
                    delegate: Column {
                        required property var modelData
                        width: (content.width - 12) / 2
                        spacing: 2
                        Heading { text: parent.modelData[0] }
                        Label {
                            width: parent.width
                            text: parent.modelData[1]
                            font.pixelSize: 11
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideNone
                        }
                    }
                }
            }

            Label {
                visible: NetworkService.connected
                text: "Totals since interface reset · Ping to 1.1.1.1"
                font.pixelSize: 10
                color: Theme.colorTextSubtle
            }

            Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }

            Column {
                width: parent.width
                spacing: 6
                Heading {
                    text: "WI-FI BAND" + (NetworkService.wifiActive.frequency
                        ? " · " + (NetworkService.wifiActive.frequency < 3000 ? "2.4 GHz"
                            : NetworkService.wifiActive.frequency < 5925 ? "5 GHz" : "6 GHz") : "")
                }
                Label {
                    width: parent.width
                    text: NetworkService.wifiProfile
                        ? "Connected Wi-Fi profile · " + (NetworkService.wifiActive.ssid || NetworkService.wifiProfile)
                        : "Connect to Wi-Fi to change its band"
                    font.pixelSize: 10
                    color: Theme.colorTextSubtle
                }
                Row {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: [{label: "Automatic", band: "auto"}, {label: "2.4 GHz", band: "bg"}, {label: "5 GHz", band: "a"}]
                        delegate: Action {
                            required property var modelData
                            width: (content.width - 12) / 3
                            text: modelData.label
                            checked: NetworkService.wifiBand === modelData.band
                            enabled: NetworkService.available && !NetworkService.busy && !!NetworkService.wifiProfile
                            Accessible.name: "Wi-Fi band " + text
                            onClicked: NetworkService.setBand(modelData.band)
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                Heading { text: "DNS · DEFAULT CONNECTION" }
                Label {
                    width: parent.width
                    text: root.dnsProfile ? "Profile: " + (NetworkService.active.name || root.dnsProfile)
                        + " (" + NetworkService.active.interface + ")" : "Connect to a network to configure DNS"
                    font.pixelSize: 10
                    color: Theme.colorTextSubtle
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                Label {
                    width: parent.width
                    visible: !!root.dnsProfile
                    text: "Current servers: " + ((NetworkService.active.dns || []).join(", ") || "Automatic")
                    font.pixelSize: 10
                    color: Theme.colorTextSubtle
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                Row {
                    width: parent.width
                    spacing: 6
                    enabled: NetworkService.available && !NetworkService.busy && !!root.dnsProfile
                    Repeater {
                        model: [{label: "Auto", mode: "auto"}, {label: "Cloudflare", mode: "cloudflare"},
                            {label: "Google", mode: "google"}, {label: "Custom", mode: "custom"}]
                        delegate: Action {
                            required property var modelData
                            width: (content.width - 18) / 4
                            text: modelData.label
                            checked: root.dnsMode === modelData.mode
                            Accessible.name: "Select DNS " + text
                            onClicked: root.dnsMode = modelData.mode
                        }
                    }
                }
                Field {
                    id: customDns
                    width: parent.width
                    visible: root.dnsMode === "custom"
                    enabled: !!root.dnsProfile && !NetworkService.busy
                    placeholderText: "DNS addresses, separated by commas"
                    Accessible.name: "Custom DNS server addresses"
                }
                Label {
                    width: parent.width
                    text: "DNS changes persist in this profile. VPN DNS may take priority."
                    font.pixelSize: 10
                    color: Theme.colorTextSubtle
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                Action {
                    width: parent.width
                    text: "Apply DNS to this profile"
                    enabled: NetworkService.available && !NetworkService.busy && !!root.dnsProfile
                        && (root.dnsMode !== "custom" || customDns.text.trim() !== "")
                    onClicked: NetworkService.setDns(root.dnsMode, customDns.text.trim())
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.colorTextMuted }

            Row {
                width: parent.width
                spacing: 8
                Heading {
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WI-FI NETWORKS"
                }
                Action {
                    width: 80
                    text: NetworkService.busy ? "Busy…" : "Scan"
                    enabled: NetworkService.available && NetworkService.wifiEnabled && !NetworkService.busy
                    Accessible.name: "Scan Wi-Fi networks"
                    onClicked: NetworkService.scan()
                }
            }

            Repeater {
                model: [true, false]
                delegate: Column {
                    id: group
                    required property bool modelData
                    readonly property var entries: NetworkService.wifiEnabled
                        ? NetworkService.networks.filter(network => !!network.known === modelData) : []
                    width: content.width
                    spacing: 5
                    Heading { text: group.modelData ? "KNOWN NETWORKS" : "OTHER NETWORKS" }
                    Repeater {
                        model: group.entries
                        delegate: NetworkRow {
                            required property var modelData
                            network: modelData
                        }
                    }
                    Label {
                        visible: group.entries.length === 0
                        text: NetworkService.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                        font.pixelSize: 11
                        color: Theme.colorTextSubtle
                    }
                }
            }

            Column {
                id: passwordEditor
                width: parent.width
                visible: root.passwordNetwork !== null
                spacing: 6
                Label {
                    width: parent.width
                    text: "Password for " + (root.passwordNetwork ? root.passwordNetwork.ssid : "")
                }
                Field {
                    id: password
                    objectName: "networkPassword"
                    width: parent.width
                    enabled: !NetworkService.busy
                    echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    placeholderText: "Password"
                    Accessible.name: "Wi-Fi password"
                    onAccepted: root.submitPassword()
                    Keys.onEscapePressed: root.cancelPassword()
                }
                Row {
                    width: parent.width
                    spacing: 6
                    Action {
                        id: showPassword
                        text: checked ? "Hide" : "Show"
                        checkable: true
                        Accessible.name: checked ? "Hide password" : "Show password"
                    }
                    Action {
                        text: "Connect"
                        enabled: NetworkService.available && NetworkService.wifiEnabled && !NetworkService.busy && password.text.length > 0
                        onClicked: root.submitPassword()
                    }
                    Action { text: "Cancel"; onClicked: root.cancelPassword() }
                }
            }

            Label {
                width: parent.width
                visible: text !== ""
                text: [NetworkService.error, NetworkService.statusError].filter(Boolean).join("\n")
                color: Theme.colorError
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                Accessible.role: Accessible.AlertMessage
            }
        }
    }
}
