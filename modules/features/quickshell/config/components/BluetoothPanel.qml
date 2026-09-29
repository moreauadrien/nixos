import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

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

    function normalizedAddress(text) {
        return String(text || "").toLowerCase().replace(/[^0-9a-f]/g, "");
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

    // Tooltip flottant interne : positionné au-dessus de l'élément survolé,
    // en coordonnées panel.
    function showTip(item, text) {
        const p = item.mapToItem(root, item.width / 2, 0);
        tipTargetX = p.x;
        tipTargetY = p.y;
        tipPendingText = text;
        tipText = "";
        tipTimer.restart();
    }

    function hideTip() {
        tipTimer.stop();
        tipPendingText = "";
        tipText = "";
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

    onDevicesChanged: {
        syncPending();
        // Une sélection merge en attente dont le device se déconnecte expire
        // (pendingMergeAddress est normalisé, les addresses BlueZ ne le sont
        // pas — comparaison en normalisé).
        if (pendingMergeAddress !== "") {
            let stillThere = false;
            for (const d of devices)
                if (d && normalizedAddress(d.address) === pendingMergeAddress) {
                    stillThere = true;
                    break;
                }
            if (!stillThere)
                pendingMergeAddress = "";
        }
        pactlRefresh.restart();
    }

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

    onPopupVisibleChanged: {
        scanStop.attempts = 0;
        if (!popupVisible)
            hideTip();
        else
            refreshPactl();
    }

    // Filet de sécurité : purge les actions qui n'aboutissent jamais.
    Timer {
        id: pendingTimer

        interval: 15000
        onTriggered: root.pendingActions = ({})
    }

    // --- combine (module-combine-sink via pactl) -------------------------------

    property var sinkNames: ({})            // adresse normalisée -> nom de sink pipewire
    property string combinedModuleIndex: ""
    property var combinedSlaveAddresses: []
    property string pendingMergeAddress: ""
    property string savedDefaultSink: ""
    property var nextCombineSlaves: []
    property string pactlMode: ""

    Timer {
        id: pactlRefresh

        interval: 500
        onTriggered: root.refreshPactl()
    }

    function refreshPactl() {
        if (!popupVisible)
            return;
        sinksProc.running = true;
        modulesProc.running = true;
    }

    function sinkAddress(sinkName) {
        const m = String(sinkName || "").match(/bluez_output\.([0-9a-f_]+)/i);
        return m ? normalizedAddress(m[1]) : "";
    }

    function isCombined(addr) {
        return combinedSlaveAddresses.indexOf(addr) !== -1;
    }

    function parseSinks(text) {
        const map = ({});
        for (const line of String(text).split("\n")) {
            const fields = line.split("\t");
            if (fields.length < 2)
                continue;
            const addr = sinkAddress(fields[1]);
            if (addr !== "")
                map[addr] = fields[1];
        }
        sinkNames = map;
    }

    function parseModules(text) {
        for (const block of String(text).split("Module #").slice(1)) {
            if (block.indexOf("module-combine-sink") === -1)
                continue;
            const idx = block.match(/^(\d+)/);
            const arg = (block.match(/slaves=([^\s"]+)/) || [])[1] || "";
            combinedModuleIndex = idx ? idx[1] : "";
            combinedSlaveAddresses = arg.split(",").map(sinkAddress).filter(a => a !== "");
            return;
        }
        combinedModuleIndex = "";
        combinedSlaveAddresses = [];
    }

    // Clic sur l'icône merge d'un device connecté : 1er clic = sélection,
    // 2e device = création du combined. Une fois le combined existant, un
    // clic sur un autre device l'ajoute (recréation), un clic sur un membre
    // le retire (recréation sans lui, destruction s'il ne reste personne).
    function mergeClicked(address) {
        const addr = normalizedAddress(address);
        if (pendingMergeAddress === addr) {
            pendingMergeAddress = "";
            return;
        }
        if (pendingMergeAddress !== "") {
            const pair = [pendingMergeAddress, addr];
            pendingMergeAddress = "";
            beginCombine(pair);
            return;
        }
        if (isCombined(addr)) {
            const rest = combinedSlaveAddresses.filter(a => a !== addr);
            if (rest.length >= 2)
                beginCombine(rest);
            else
                destroyCombined();
            return;
        }
        if (combinedSlaveAddresses.length > 0) {
            beginCombine(combinedSlaveAddresses.concat([addr]));
            return;
        }
        pendingMergeAddress = addr;
    }

    function beginCombine(slaves) {
        nextCombineSlaves = slaves.map(normalizedAddress);
        if (combinedModuleIndex === "") {
            // première création : sauvegarder le sink par défaut pour le
            // restaurer à la destruction du combined
            pactlMode = "save-default";
            getDefault.running = true;
        } else {
            pactlMode = "unload-recreate";
            pactlAction.command = ["pactl", "unload-module", combinedModuleIndex];
            pactlAction.running = true;
        }
    }

    function startLoad() {
        const names = nextCombineSlaves.map(a => sinkNames[a] || "").filter(n => n !== "");
        if (names.length < 2) {
            restoreDefaultSink();
            return;
        }
        pactlMode = "load";
        pactlAction.command = ["pactl", "load-module", "module-combine-sink", "sink_name=combined", "slaves=" + names.join(",")];
        pactlAction.running = true;
    }

    function destroyCombined() {
        if (combinedModuleIndex === "")
            return;
        pactlMode = "unload-destroy";
        pactlAction.command = ["pactl", "unload-module", combinedModuleIndex];
        pactlAction.running = true;
    }

    function restoreDefaultSink() {
        pactlMode = "";
        if (savedDefaultSink !== "" && savedDefaultSink !== "combined") {
            defaultSinkProc.command = ["pactl", "set-default-sink", savedDefaultSink];
            defaultSinkProc.running = true;
        }
        savedDefaultSink = "";
    }

    Process {
        id: sinksProc

        command: ["pactl", "list", "short", "sinks"]

        stdout: StdioCollector {
            id: sinksOut

            onStreamFinished: root.parseSinks(sinksOut.text)
        }
    }

    Process {
        id: modulesProc

        command: ["pactl", "list", "modules"]

        stdout: StdioCollector {
            id: modulesOut

            onStreamFinished: root.parseModules(modulesOut.text)
        }
    }

    Process {
        id: getDefault

        command: ["pactl", "get-default-sink"]

        stdout: StdioCollector {
            id: defaultOut

            onStreamFinished: {
                if (root.pactlMode === "save-default") {
                    root.savedDefaultSink = defaultOut.text.trim();
                    root.startLoad();
                }
            }
        }
    }

    Process {
        id: pactlAction

        onExited: {
            if (root.pactlMode === "load") {
                root.pactlMode = "set-default";
                defaultSinkProc.command = ["pactl", "set-default-sink", "combined"];
                defaultSinkProc.running = true;
            } else if (root.pactlMode === "unload-destroy") {
                root.restoreDefaultSink();
            } else if (root.pactlMode === "unload-recreate") {
                root.startLoad();
            }
            root.refreshPactl();
        }
    }

    Process {
        id: defaultSinkProc

        onExited: root.refreshPactl()
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

    // --- tooltip flottant ----------------------------------------------------

    property string tipText: ""
    property string tipPendingText: ""
    property real tipTargetX: 0
    property real tipTargetY: 0

    // Le tip ne s'affiche qu'après 500ms de hover continu.
    Timer {
        id: tipTimer

        interval: 500
        onTriggered: root.tipText = root.tipPendingText
    }

    Rectangle {
        id: tip

        visible: root.tipText !== ""
        width: tipLabel.implicitWidth + 14
        height: tipLabel.implicitHeight + 8
        radius: 4
        color: Theme.background
        border.color: Theme.muted
        border.width: 1
        x: Math.max(0, Math.min(root.width - width, root.tipTargetX - width / 2))
        y: Math.max(0, root.tipTargetY - height - 6)
        z: 10

        Text {
            id: tipLabel

            anchors.centerIn: parent
            text: root.tipText
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    // --- composants locaux ----------------------------------------------------

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

        readonly property string addrNorm: root.normalizedAddress(modelData.address)
        readonly property bool inCombined: root.combinedSlaveAddresses.includes(addrNorm)
        readonly property bool mergeSelected: root.pendingMergeAddress === addrNorm
        readonly property bool hovered: rowMouse.containsMouse || mergeMouse.containsMouse || crossMouse.containsMouse

        width: parent.width
        height: 48
        radius: 4
        color: hovered ? Qt.alpha(Theme.foreground, 0.08) : "transparent"
        border.width: hovered ? 1 : 0
        border.color: Theme.muted

        function updateTip() {
            if (mergeMouse.containsMouse)
                root.showTip(deviceRow, deviceRow.inCombined ? "Unmerge" : "Merge");
            else if (crossMouse.containsMouse)
                root.showTip(forgetCross, "Forget");
            else if (rowMouse.containsMouse)
                root.showTip(deviceRow, deviceRow.modelData.connected ? "Disconnect" : deviceRow.kind === "discovered" ? "Pair" : "Connect");
            else
                root.hideTip();
        }

        // Déclaré en PREMIER : les clics vont à l'élément le plus haut — si
        // rowMouse était après les boutons, il volait leurs clics (les hover
        // events, eux, sont diffusés à toutes les MouseAreas, donc le highlight
        // de ligne marche toujours).
        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.hideTip();
                root.activateRow(deviceRow.modelData.address);
            }
            onContainsMouseChanged: deviceRow.updateTip()
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

        // Icône merge (combine-sink) : devices connectés uniquement.
        // 1er clic = sélection, 2e device = création, clic sur un membre =
        // retrait. Surbrillance accent quand sélectionné ou membre.
        // (Pas de gating sur la présence d'un sink pipewire : si pactl échoue
        // le bouton doit rester visible, le combine échouera juste sans
        // effet — et l'absence de bouton est indifférenciable d'un bug.)
        Rectangle {
            id: mergeButton

            visible: deviceRow.kind === "connected"
            width: 22
            height: 22
            radius: 11
            anchors.right: parent.right
            anchors.rightMargin: 38
            anchors.verticalCenter: parent.verticalCenter
            color: mergeMouse.containsMouse ? Qt.alpha(Theme.accent, 0.15) : "transparent"

            Text {
                text: "\uE727"
                color: deviceRow.mergeSelected || deviceRow.inCombined ? Theme.accent : mergeMouse.containsMouse ? Theme.foreground : Theme.muted
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 16
            }

            MouseArea {
                id: mergeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.hideTip();
                    root.mergeClicked(deviceRow.modelData.address);
                }
                onContainsMouseChanged: deviceRow.updateTip()
            }
        }

        // Croix « forget » : toujours visible sur les devices connectés et
        // appairés. (Visible seulement au hover, elle disparaissait quand la
        // souris l'atteignait : containsMouse est exclusif entre siblings.)
        Rectangle {
            id: forgetCross

            visible: deviceRow.kind === "connected" || deviceRow.kind === "known"
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
                onClicked: {
                    root.hideTip();
                    root.forgetDevice(deviceRow.modelData.address);
                }
                onContainsMouseChanged: deviceRow.updateTip()
            }
        }

        // Découverts : pas de bouton — le tooltip « Pair » au hover suffit,
        // le clic sur la ligne lance pair+connect.
    }
}
