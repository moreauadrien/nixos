pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var data: ({})
    property bool available: false
    property bool busy: false
    property int openPanels: 0
    property string error: ""
    property string statusError: ""
    property real rxRate: 0
    property real txRate: 0
    property real pingMs: -1
    property real packetLoss: -1
    property var previous: ({})
    readonly property var active: data.active || ({})
    readonly property bool connected: !!active.interface
    readonly property bool wifiEnabled: !!data.wifiEnabled
    readonly property var networks: (data.networks || []).filter(n => n.ssid).slice().sort((a, b) =>
        Number(b.active) - Number(a.active) || Number(b.known) - Number(a.known) || b.signal - a.signal)
        .filter((network, index, all) => all.findIndex(n => n.ssid === network.ssid
            && n.interface === network.interface && n.security === network.security) === index)
    readonly property var wifiActive: networks.find(n => n.active) || ({})
    readonly property string wifiProfile: ((data.devices || []).find(d => d.type === "wifi" && d.uuid) || {}).uuid || ""
    readonly property string wifiBand: active.type === "wifi" ? (active.band || "auto") : (data.wifiBand || "auto")
    readonly property string icon: connected ? (active.type === "ethernet" ? "󰈀" : "󰖩") : "󰖪"
    readonly property string status: busy ? "WORKING…" : !available ? "UNAVAILABLE"
        : connected ? (active.type === "ethernet" ? "WIRED CONNECTION" : "CONNECTED")
        : wifiEnabled ? "DISCONNECTED" : "WI-FI OFF"

    function formatBytes(value) {
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let index = 0;
        value = Math.max(0, Number(value) || 0);
        while (value >= 1024 && index < units.length - 1) { value /= 1024; index++; }
        return value.toFixed(index ? 1 : 0) + " " + units[index];
    }

    function refresh() { if (!query.running && !busy) query.running = true; }
    function scan() { run({action: "scan"}); }
    function connect(network, password = "") {
        const request = {action: "connect", bssid: network.bssid, interface: network.interface,
            uuid: network.uuid || ""};
        if (password) request.password = password;
        run(request);
    }
    function disconnect(iface) { run({action: "disconnect", interface: iface}); }
    function forget(uuid) { run({action: "forget", uuid: uuid}); }
    function setDns(mode, servers = "") {
        if (active.uuid) run({action: "dns", uuid: active.uuid, mode: mode, servers: servers});
    }
    function setBand(band) {
        if (wifiProfile) run({action: "band", uuid: wifiProfile, band: band});
    }
    function run(request) {
        if (busy || !available) return;
        error = "";
        busy = true;
        action.payload = JSON.stringify(request);
        action.running = true;
    }

    onOpenPanelsChanged: if (openPanels > 0) { refresh(); probeNow(); }
    Component.onCompleted: refresh()
    function probeNow() {
        if (openPanels > 0 && connected && !probe.running) {
            probe.command = ["network-control", "probe", active.interface];
            probe.running = true;
        }
    }
    Timer {
        interval: root.openPanels > 0 ? 2000 : 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    Timer {
        interval: 10000
        running: root.openPanels > 0
        repeat: true
        onTriggered: root.probeNow()
    }
    Process {
        id: query
        command: ["network-control", "status"]
        property string output: ""
        onStarted: { output = ""; queryTimeout.restart(); }
        stdout: StdioCollector { onStreamFinished: query.output = text }
        onExited: (code, exitStatus) => {
            queryTimeout.stop();
            try {
                const result = JSON.parse(output);
                if (code !== 0 || !result.available) throw new Error(result.error || "NetworkManager unavailable");
                const current = result.active || {};
                const now = Date.now();
                const elapsed = (now - (root.previous.time || now)) / 1000;
                const same = current.interface && current.interface === root.previous.interface && elapsed > 0;
                root.rxRate = same ? Math.max(0, (current.rxBytes - root.previous.rxBytes) / elapsed) : 0;
                root.txRate = same ? Math.max(0, (current.txBytes - root.previous.txBytes) / elapsed) : 0;
                if (current.interface !== root.active.interface) { root.pingMs = -1; root.packetLoss = -1; }
                root.previous = {interface: current.interface, rxBytes: current.rxBytes, txBytes: current.txBytes, time: now};
                root.data = result;
                root.available = true;
                root.statusError = "";
                if (root.pingMs < 0) root.probeNow();
            } catch (e) {
                root.available = false;
                root.data = ({});
                root.previous = ({});
                root.rxRate = 0; root.txRate = 0;
                root.pingMs = -1; root.packetLoss = -1;
                root.statusError = "Unable to read network status. Is network-control installed?";
            }
        }
    }
    Timer { id: queryTimeout; interval: 30000; onTriggered: query.running = false }
    Process {
        id: action
        command: ["network-control", "action"]
        stdinEnabled: true
        property string payload: ""
        property string output: ""
        onStarted: {
            output = "";
            write(payload + "\n");
            payload = "";
            stdinEnabled = false;
            actionTimeout.restart();
        }
        stdout: StdioCollector { onStreamFinished: action.output = text }
        onExited: (code, exitStatus) => {
            actionTimeout.stop();
            payload = "";
            stdinEnabled = true;
            root.busy = false;
            try {
                const result = JSON.parse(output);
                if (code !== 0 || !result.ok) root.error = result.error || "Network operation failed";
            } catch (e) { root.error = "Network operation failed"; }
            root.refresh();
        }
    }
    Timer {
        id: actionTimeout
        interval: 120000
        onTriggered: { action.running = false; root.error = "Network operation timed out"; }
    }
    Process {
        id: probe
        property string output: ""
        property string iface: ""
        onStarted: { output = ""; iface = root.active.interface; }
        stdout: StdioCollector { onStreamFinished: probe.output = text }
        onExited: (code, exitStatus) => {
            if (iface !== root.active.interface) return;
            try {
                const result = JSON.parse(output);
                root.pingMs = result.pingMs === null ? -1 : Number(result.pingMs);
                root.packetLoss = result.packetLoss === null ? -1 : Number(result.packetLoss);
            } catch (e) { root.pingMs = -1; root.packetLoss = -1; }
        }
    }
}
