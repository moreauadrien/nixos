pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    signal showRequested()
    signal hideRequested()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    property bool panelOpen: false
    property bool scanOwned: false
    property var pending: ({})

    // BlueZ may destroy device QObjects during discovery. The UI only gets values;
    // actions resolve the current QObject by address at the time of the click.
    readonly property var sections: {
        const connected = [], paired = [], available = [];
        for (const d of (Bluetooth.devices ? Bluetooth.devices.values : [])) {
            if (!d || !d.address) continue;
            const name = String(d.name || d.deviceName || "").trim();
            if (!name || /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(name)) continue;
            const row = { address: d.address, name: name, connected: d.connected,
                known: d.paired || d.bonded || d.trusted,
                battery: d.batteryAvailable ? Math.round(d.battery * 100) : -1,
                busy: d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting,
                pending: pending[d.address] || "" };
            if (row.connected) connected.push(row);
            else if (row.known) paired.push(row);
            else if (adapter && adapter.discovering) available.push(row);
        }
        for (const list of [connected, paired, available])
            list.sort((a, b) => a.name.localeCompare(b.name));
        return [
            { title: "CONNECTED", rows: connected },
            { title: "PAIRED", rows: paired },
            { title: "AVAILABLE", rows: available }
        ];
    }
    readonly property var connectedNames: sections[0].rows.map(row => row.name)
    readonly property bool hasDevices: sections.some(section => section.rows.length > 0)
    readonly property string status: !adapter ? "NO ADAPTER" : !powered ? "TURNED OFF"
        : adapter.discovering ? "SCANNING" : connectedNames.length ? connectedNames.length + " CONNECTED" : "NO DEVICES"

    function deviceFor(address) {
        for (const d of (Bluetooth.devices ? Bluetooth.devices.values : []))
            if (d && d.address === address) return d;
        return null;
    }

    function mark(address, action) {
        pending = Object.assign({}, pending, { [address]: action });
        pendingTimeout.restart();
    }

    function togglePower() {
        if (adapter) adapter.enabled = !adapter.enabled;
    }

    function activate(address) {
        const d = deviceFor(address);
        if (!d || !powered || pending[address]) return;
        if (d.connected) {
            mark(address, "Disconnecting…");
            d.disconnect();
        } else {
            mark(address, "Connecting…");
            if (d.paired || d.bonded || d.trusted) {
                connectIssued = Object.assign({}, connectIssued, { [address]: true });
                d.connect();
            }
            else d.pair();
        }
    }

    function forget(address) {
        const d = deviceFor(address);
        if (!d || !powered || pending[address]) return;
        mark(address, "Forgetting…");
        d.forget();
    }

    function syncPending() {
        const next = Object.assign({}, pending);
        let changed = false;
        for (const address in next) {
            const d = deviceFor(address);
            const action = next[address];
            if (action === "Connecting…" && d && !d.connected && (d.paired || d.bonded || d.trusted) && !d.pairing) {
                // Pair() does not necessarily connect; do it once after pairing.
                if (!connectIssued[address]) {
                    connectIssued = Object.assign({}, connectIssued, { [address]: true });
                    d.connect();
                }
            }
            if ((action === "Connecting…" && d && d.connected)
                || (action === "Disconnecting…" && (!d || !d.connected))
                || (action === "Forgetting…" && (!d || !(d.paired || d.bonded || d.trusted)))) {
                delete next[address];
                changed = true;
            }
        }
        if (changed) pending = next;
    }
    property var connectIssued: ({})

    Timer {
        interval: 1000
        repeat: true
        running: root.panelOpen && Object.keys(root.pending).length > 0
        onTriggered: root.syncPending()
    }
    Timer {
        id: pendingTimeout
        interval: 20000
        onTriggered: { root.pending = ({}); root.connectIssued = ({}); }
    }

    onPanelOpenChanged: {
        if (!panelOpen && scanOwned && adapter && adapter.discovering) adapter.discovering = false;
    }
    // Retry while the popup is visible: BlueZ can refuse a scan immediately after power-on.
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.panelOpen && root.powered && !root.adapter.discovering
        onTriggered: { root.scanOwned = true; root.adapter.discovering = true; }
    }
    // A pending StartDiscovery may be confirmed *after* closing the popup.
    Timer {
        interval: 1000
        repeat: true
        running: !root.panelOpen && root.scanOwned && root.adapter !== null && root.adapter.discovering
        onTriggered: root.adapter.discovering = false
    }
    Connections {
        target: root.adapter
        function onDiscoveringChanged() {
            if (!root.adapter.discovering && !root.panelOpen) root.scanOwned = false;
        }
    }

    IpcHandler {
        target: "bluetooth"
        function show() { root.showRequested(); }
        function hide() { root.hideRequested(); }
        function togglePower() { root.togglePower(); }
        function isOpen(): bool { return root.panelOpen; }
        function rowCount(): int { return root.sections.reduce((n, section) => n + section.rows.length, 0); }
    }
}
