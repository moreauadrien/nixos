pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var data: ({})
    property bool available: false
    property int openPanels: 0
    readonly property bool panelOpen: openPanels > 0
    property string error: ""
    property string statusError: ""
    property bool busy: false
    readonly property bool connected: available && data.BackendState === "Running"
    readonly property string hostname: (data.Self || {}).HostName || "Tailscale"
    readonly property string authUrl: data.AuthURL || ""
    readonly property var peers: Object.values(data.Peer || {}).sort((a, b) =>
        Number(b.Online) - Number(a.Online) || name(a).localeCompare(name(b)))
    readonly property var exitNodes: peers.filter(peer => peer.ExitNodeOption || peer.ExitNode)
    readonly property string exitId: (data.ExitNodeStatus || {}).ID || (peers.find(peer => peer.ExitNode) || {}).ID || ""
    readonly property string status: busy ? "WORKING…" : !available ? "UNAVAILABLE"
        : connected ? "CONNECTED" : data.BackendState === "NeedsLogin" ? "LOGIN REQUIRED"
        : data.BackendState === "NeedsMachineAuth" ? "AWAITING ADMIN APPROVAL" : "TAILSCALE IS DISCONNECTED"

    function name(peer) {
        return ((peer || {}).DNSName || "").split(".")[0] || (peer || {}).HostName || "Unknown";
    }

    function domain(peer) {
        return ((peer || {}).DNSName || "").replace(/\.$/, "");
    }

    function ip(peer, ipv6 = false) {
        return ((peer || {}).TailscaleIPs || []).find(address => address.includes(":") === ipv6) || "";
    }

    function refresh() {
        if (!query.running) query.running = true;
    }

    function run(args) {
        if (busy || !available) return;
        error = "";
        busy = true;
        action.command = ["tailscale"].concat(args);
        action.running = true;
        actionTimeout.restart();
    }

    function toggle() {
        // No flags: reconnect without resetting existing Tailscale preferences.
        run([connected ? "down" : "up"]);
    }

    function selectExit(id) {
        if (!connected || busy) return;
        const peer = exitNodes.find(node => node.ID === id);
        if (id && (!peer || !peer.Online || !ip(peer))) return;
        run(["set", "--exit-node=" + (id ? ip(peer) : "")]);
    }

    function copy(value) {
        if (value) Quickshell.execDetached(["wl-copy", "--", value]);
    }

    onPanelOpenChanged: if (panelOpen) refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: root.panelOpen || root.busy ? 2000 : 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: query
        command: ["tailscale", "status", "--json"]
        property string output: ""
        property string failure: ""
        onStarted: { output = ""; failure = ""; queryTimeout.restart(); }
        stdout: StdioCollector { onStreamFinished: query.output = text }
        stderr: StdioCollector { onStreamFinished: query.failure = text }
        onExited: (code, exitStatus) => {
            queryTimeout.stop();
            try {
                const result = JSON.parse(output);
                if (!result.BackendState) throw new Error("Missing Tailscale state");
                root.data = result;
                root.available = true;
                root.statusError = "";
            } catch (e) {
                root.available = false;
                root.data = ({});
                root.statusError = failure.trim() || "Unable to read Tailscale status";
            }
        }
    }

    Timer {
        id: queryTimeout
        interval: 10000
        onTriggered: query.running = false
    }

    Process {
        id: action
        property string output: ""
        onStarted: output = ""
        stdout: SplitParser { onRead: line => action.output += line + "\n" }
        stderr: SplitParser { onRead: line => action.output += line + "\n" }
        onExited: (code, exitStatus) => {
            actionTimeout.stop();
            root.busy = false;
            if (code !== 0) root.error = output.trim() || "Tailscale command failed (" + code + ")";
            root.refresh();
        }
    }

    Timer {
        id: actionTimeout
        interval: 120000
        onTriggered: {
            action.running = false;
            root.busy = false;
            root.error = "Tailscale timed out. Complete login in your browser, then try again.";
        }
    }
}
