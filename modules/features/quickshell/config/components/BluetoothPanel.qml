import QtQuick
import Quickshell
import Quickshell.Bluetooth

import "../services"

// Contenu du popup Bluetooth : hero (titre + toggle power), sections
// CONNECTED / PAIRED / AVAILABLE, actions inline révélées au hover
// (Pair / Connect / Disconnect / Forget). Souris uniquement.
//
// Scan : démarre quand le popup s'ouvre (popupVisible) si l'adapter est on,
// s'arrête à la fermeture. BlueZ peut refuser StartDiscovery tant que
// l'adapter démarre, et ignorer un Stop trop rapide d'un just-fired
// StartDiscovery — d'où les deux timers retry (idée reprise d'Omarchy).
//
// Les delegates ne reçoivent que des projections primitives (rowFor) ; les
// actions re-résolvent le device BlueZ live par adresse. Garder un wrapper
// QObject dans un delegate pendant un churn de découverte segfault
// quickshell (cf. Omarchy Model.js).
Item {
    id: root

    property bool popupVisible: false
    property var pendingActions: ({})

    implicitWidth: 400
    implicitHeight: column.height

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool hasAdapter: adapter !== null
    readonly property bool powered: hasAdapter && adapter.enabled
    readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
    readonly property bool discovering: hasAdapter && adapter.discovering

    // --- helpers -------------------------------------------------------------

    function isAddressLike(text) {
        return /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(String(text || "").trim());
    }

    function humanName(device) {
        const name = String(device && device.name ? device.name : "").trim();
        return name !== "" && !isAddressLike(name) ? name : "";
    }

    // Projection primitives-only d'un device BlueZ pour les lignes de liste.
    function rowFor(d) {
        return {
            address: d.address || "",
            name: humanName(d),
            connected: !!d.connected,
            paired: !!(d.paired || d.bonded || d.trusted),
            batteryAvailable: !!d.batteryAvailable,
            // quickshell expose battery en fraction 0..1 → pourcentage.
            battery: d.battery !== undefined ? Math.round((d.battery || 0) * 100) : 0
        };
    }

    function deviceByAddress(address) {
        for (const d of devices)
            if (d && d.address === address)
                return d;
        return null;
    }

    function pendingLabel(address) {
        const action = pendingActions[address];
        if (action === "connecting")
            return "Connecting…";
        if (action === "disconnecting")
            return "Disconnecting…";
        if (action === "forgetting")
            return "Forgetting…";
        return "";
    }

    function setPending(address, action) {
        if (!address)
            return;
        const next = Object.assign({}, pendingActions);
        next[address] = action;
        pendingActions = next;
        pendingTimer.restart();
    }

    function connectDevice(address) {
        const d = deviceByAddress(address);
        if (!d || d.connected)
            return;
        setPending(address, "connecting");
        if (d.paired || d.bonded || d.trusted) {
            if (d.connect)
                d.connect();
        } else if (d.pair) {
            d.pair();
        }
    }

    function disconnectDevice(address) {
        const d = deviceByAddress(address);
        if (!d || !d.connected)
            return;
        setPending(address, "disconnecting");
        if (d.disconnect)
            d.disconnect();
    }

    function forgetDevice(address) {
        if (!deviceByAddress(address))
            return;
        setPending(address, "forgetting");
        const d = deviceByAddress(address);
        if (d.forget)
            d.forget();
    }

    // Ligne cliquée : device connecté → disconnect ; sinon connect (pair
    // d'abord si besoin).
    function activateRow(address) {
        const d = deviceByAddress(address);
        if (!d)
            return;
        if (d.connected)
            disconnectDevice(address);
        else
            connectDevice(address);
    }

    // Nettoyage des actions terminées ; enchaîne le connect après un pair
    // réussi (BlueZ ne connecte pas toujours seul après pair).
    function syncPending() {
        const next = Object.assign({}, pendingActions);
        let changed = false;
        for (const address in next) {
            const action = next[address];
            const d = deviceByAddress(address);
            const paired = d && (d.paired || d.bonded || d.trusted);
            if (action === "connecting" && d) {
                if (d.connected) {
                    delete next[address];
                    changed = true;
                } else if (paired && !d.connected && d.connect) {
                    d.connect();
                }
            } else if (action === "disconnecting" && d && !d.connected) {
                delete next[address];
                changed = true;
            } else if (action === "forgetting" && (!d || !paired)) {
                delete next[address];
                changed = true;
            }
        }
        if (changed)
            pendingActions = next;
    }

    onDevicesChanged: syncPending()

    readonly property var sections: {
        const connected = [], known = [], discovered = [];
        for (const d of devices) {
            if (!d || humanName(d) === "")
                continue;
            if (d.connected)
                connected.push(d);
            else if (d.paired || d.bonded || d.trusted)
                known.push(d);
            else
                discovered.push(d);
        }
        const byName = (a, b) => humanName(a).localeCompare(humanName(b));
        connected.sort(byName);
        known.sort(byName);
        discovered.sort(byName);
        return [
            {
                title: "CONNECTED",
                kind: "connected",
                rows: connected.map(rowFor)
            },
            {
                title: "PAIRED",
                kind: "known",
                rows: known.map(rowFor)
            },
            {
                title: "AVAILABLE",
                kind: "discovered",
                rows: powered && discovering ? discovered.map(rowFor) : []
            }
        ];
    }

    readonly property string heroSubtitle: {
        if (!hasAdapter)
            return "NO ADAPTER";
        if (!powered)
            return "TURNED OFF";
        if (discovering)
            return "SCANNING";
        if (sections[0].rows.length > 0)
            return sections[0].rows.length + " CONNECTED";
        return "NO DEVICES";
    }

    readonly property bool hasAnyRows: sections.some(s => s.rows.length > 0)

    readonly property string footerText: {
        if (!hasAdapter)
            return "No Bluetooth adapter";
        if (!powered)
            return "Turn Bluetooth on to scan";
        // Comme la référence : le footer de statut ne s'affiche que s'il n'y
        // a aucune section à montrer.
        if (!hasAnyRows && discovering)
            return "Scanning for devices…";
        return "";
    }

    // --- scan ---------------------------------------------------------------

    Timer {
        id: scanStart

        interval: 800
        triggeredOnStart: true
        running: root.popupVisible && root.powered && !root.discovering
        onTriggered: {
            if (root.hasAdapter)
                root.adapter.discovering = true;
        }
    }

    Timer {
        id: scanStop

        property int attempts: 0

        interval: 800
        triggeredOnStart: true
        running: !root.popupVisible && root.hasAdapter && root.adapter.discovering
        onTriggered: {
            attempts += 1;
            if (attempts > 3) {
                running = false;
                return;
            }
            root.adapter.discovering = false;
        }
    }

    onPopupVisibleChanged: scanStop.attempts = 0

    // Filet de sécurité : purge les actions qui n'aboutissent jamais.
    Timer {
        id: pendingTimer

        interval: 15000
        onTriggered: root.pendingActions = ({})
    }

    // --- layout -------------------------------------------------------------

    Column {
        id: column

        width: root.implicitWidth
        spacing: 12

        Item {
            width: parent.width
            height: 54

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    text: "󰂯"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Bluetooth"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: root.heroSubtitle
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }
                }
            }

            Rectangle {
                id: powerToggle

                visible: root.hasAdapter
                width: 44
                height: 24
                radius: 12
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: root.powered ? Theme.accent : Theme.muted
                border.width: 1
                border.color: root.powered ? Theme.accent : Theme.muted

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.powered ? parent.width - width - 3 : 3
                    width: 18
                    height: 18
                    radius: 9
                    color: Theme.foreground

                    Behavior on x {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.hasAdapter)
                            root.adapter.enabled = !root.adapter.enabled;
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.muted
        }

        Repeater {
            model: root.sections

            delegate: Column {
                required property var modelData

                width: column.width
                spacing: 6
                visible: modelData.rows.length > 0
                height: visible ? implicitHeight : 0

                Text {
                    text: modelData.title
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                }

                Repeater {
                    model: modelData.rows

                    delegate: DeviceRow {}
                }
            }
        }

        Text {
            text: root.footerText
            visible: root.footerText !== ""
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
    }

    // --- composants locaux ----------------------------------------------------

    component ActionButton: Rectangle {
        id: actionButton

        property string label
        signal clicked()

        width: actionLabel.implicitWidth + 18
        height: actionLabel.implicitHeight + 8
        radius: 4
        color: Theme.background
        border.color: actionMouse.containsMouse ? Theme.accent : Theme.muted
        border.width: 1

        Text {
            id: actionLabel

            anchors.centerIn: parent
            text: actionButton.label
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        MouseArea {
            id: actionMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.clicked()
        }
    }

    component DeviceRow: Rectangle {
        id: deviceRow

        required property var modelData

        readonly property string kind: {
            for (const s of root.sections)
                for (const r of s.rows)
                    if (r.address === modelData.address)
                        return s.kind;
            return "known";
        }
        readonly property string pending: root.pendingLabel(modelData.address)
        readonly property string sublabel: {
            if (pending !== "")
                return pending;
            if (modelData.connected && modelData.batteryAvailable)
                return modelData.battery + "%";
            return "";
        }

        width: parent.width
        height: 48
        radius: 4
        color: rowMouse.containsMouse ? Qt.alpha(Theme.foreground, 0.08) : "transparent"
        border.width: rowMouse.containsMouse ? 1 : 0
        border.color: Theme.muted

        // Déclaré en PREMIER : les clics vont à l'élément le plus haut — si
        // rowMouse était après les boutons, il volait leurs clics (les hover
        // events, eux, sont diffusés à toutes les MouseAreas, donc le highlight
        // de ligne marche toujours).
        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activateRow(deviceRow.modelData.address)
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Text {
                text: deviceRow.modelData.connected ? "󰂱" : "󰂯"
                color: deviceRow.modelData.connected ? Theme.accent : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: deviceRow.modelData.name
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }

                Text {
                    text: deviceRow.sublabel
                    visible: deviceRow.sublabel !== ""
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }

        // Croix « forget » : toujours visible sur les devices connectés (comme
        // la référence), au hover sur les devices appairés.
        Rectangle {
            id: forgetCross

            visible: deviceRow.kind === "connected" || (deviceRow.kind === "known" && rowMouse.containsMouse)
            width: 22
            height: 22
            radius: 11
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: crossMouse.containsMouse ? Qt.alpha(Theme.urgent, 0.2) : "transparent"

            Text {
                text: "󰅖"
                color: crossMouse.containsMouse ? Theme.urgent : Theme.muted
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }

            MouseArea {
                id: crossMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.forgetDevice(deviceRow.modelData.address)
            }
        }

        ActionButton {
            visible: deviceRow.kind === "discovered" && rowMouse.containsMouse
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            label: "Pair"
            onClicked: root.connectDevice(deviceRow.modelData.address)
        }
    }
}
