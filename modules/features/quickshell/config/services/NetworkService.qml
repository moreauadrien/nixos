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
    property var connectingNetwork: null
    property string connectionMessage: ""
    signal connectionFinished(var network, bool success)
    readonly property var active: data.active || ({})
    readonly property bool connected: !!active.interface
    readonly property bool wifiEnabled: !!data.wifiEnabled
    readonly property var ethernet: (data.devices || []).filter(d => d.type === "ethernet")
    readonly property var networks: (data.networks || []).filter(n => n.ssid).slice().sort((a, b) =>
        Number(b.active) - Number(a.active) || Number(b.known) - Number(a.known) || b.signal - a.signal)
        .filter((network, index, all) => all.findIndex(n => n.ssid === network.ssid
            && n.interface === network.interface && n.security === network.security) === index)
    readonly property string icon: connected ? (active.type === "ethernet" ? "󰈀" : "󰖩") : "󰖪"
    readonly property string status: connectingNetwork ? "CONNECTING…" : busy ? "WORKING…" : !available ? "UNAVAILABLE"
        : connected ? (active.type === "ethernet" ? "WIRED CONNECTION" : "CONNECTED")
        : wifiEnabled ? "DISCONNECTED" : "WI-FI OFF"

    function refresh() { if (!query.running && !busy) query.running = true; }
    function scan() { run({action: "scan"}); }
    function connect(network, password = "") {
        const request = {action: "connect", bssid: network.bssid, interface: network.interface,
            uuid: network.uuid || ""};
        if (password) request.password = password;
        run(request, network);
    }
    function disconnect(iface) { run({action: "disconnect", interface: iface}); }
    function forget(uuid) { run({action: "forget", uuid: uuid}); }
    function run(request, network = null) {
        if (busy || !available) return;
        error = "";
        connectingNetwork = network;
        connectionMessage = network ? "Connecting to " + network.ssid + "…" : "";
        busy = true;
        action.payload = JSON.stringify(request);
        action.running = true;
    }
    onOpenPanelsChanged: if (openPanels > 0) refresh()
    Component.onCompleted: refresh()
    Timer {
        interval: root.openPanels > 0 ? 3000 : 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
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
                if (code !== 0 || !result.available) throw new Error("NetworkManager unavailable");
                root.data = result;
                root.available = true;
                root.statusError = "";
            } catch (e) {
                root.available = false;
                root.data = ({});
                root.statusError = "Unable to read network status";
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
        property bool timedOut: false
        onStarted: {
            timedOut = false;
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
            try {
                const result = JSON.parse(output);
                if (code !== 0 || !result.ok) root.error = result.error || "Network operation failed";
            } catch (e) { root.error = "Network operation failed"; }
            if (timedOut) root.error = "Connection timed out. Check the password and signal, then try again.";
            const network = root.connectingNetwork;
            root.connectingNetwork = null;
            root.busy = false;
            if (network) {
                const success = root.error === "";
                root.connectionMessage = success ? "Connected to " + network.ssid
                    : "Could not connect to " + network.ssid + ". Try again.";
                root.connectionFinished(network, success);
            }
            root.refresh();
        }
    }
    Timer {
        id: actionTimeout
        interval: 120000
        onTriggered: { action.timedOut = true; action.running = false; }
    }
}
