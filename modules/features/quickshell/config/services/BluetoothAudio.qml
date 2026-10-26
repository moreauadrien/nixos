pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var sinks: ({}) // Bluetooth address -> PipeWire sink name
    property var volumes: ({}) // Bluetooth address -> sink volume in percent
    property var combined: []
    property string moduleId: ""
    property string selected: ""
    property string previousDefault: ""
    property string error: ""
    property bool busy: false
    property string step: ""

    function addressFromSink(name) {
        const match = String(name).match(/^bluez_output\.([0-9a-f]{2}(?:_[0-9a-f]{2}){5})(?:\.|$)/i);
        return match ? match[1].replace(/_/g, ":").toUpperCase() : "";
    }

    function refresh() {
        if (!busy && !sinksProc.running && !modulesProc.running) {
            sinksProc.running = true;
            modulesProc.running = true;
        }
    }

    function toggle(address) {
        address = String(address).toUpperCase();
        if (busy) return;
        error = "";
        if (combined.includes(address)) {
            selected = "";
            unmerge();
        } else if (moduleId) {
            error = "Remove the current mix first";
        } else if (!sinks[address]) {
            error = "No audio output for this device";
            refresh();
        } else if (selected === address) {
            selected = "";
        } else if (!selected) {
            selected = address;
        } else {
            const first = selected;
            selected = "";
            if (!sinks[first]) {
                error = "First audio output disconnected";
                refresh();
                return;
            }
            busy = true;
            step = "read-default";
            action.command = ["pactl", "get-default-sink"];
            action.running = true;
            pending = [first, address];
        }
    }

    property var pending: []

    function setVolume(address, percent) {
        address = String(address).toUpperCase();
        if (!combined.includes(address) || !sinks[address]) return;
        percent = Math.max(0, Math.min(100, Math.round(percent)));
        volumes = Object.assign({}, volumes, { [address]: percent });
        volumeQueue.push([sinks[address], percent]);
        runVolumeQueue();
    }

    property var volumeQueue: []

    function runVolumeQueue() {
        if (volumeAction.running || !volumeQueue.length) return;
        const next = volumeQueue.shift();
        volumeAction.command = ["pactl", "set-sink-volume", next[0], next[1] + "%"];
        volumeAction.running = true;
    }

    function unmerge() {
        if (!moduleId) return;
        busy = true;
        step = "unload";
        action.command = ["pactl", "unload-module", moduleId];
        action.running = true;
    }

    function runAction(command, nextStep) {
        step = nextStep;
        action.command = command;
        action.running = true;
    }

    Process {
        id: sinksProc
        command: ["pactl", "list", "short", "sinks"]
        stdout: StdioCollector { id: sinksOut }
        onExited: (code) => {
            if (code !== 0) return;
            const found = {};
            for (const line of sinksOut.text.split("\n")) {
                const name = line.split("\t")[1] || "";
                const address = root.addressFromSink(name);
                if (address) found[address] = name;
            }
            root.sinks = found;
            if (root.combined.length && !volumesProc.running && !volumeAction.running) volumesProc.running = true;
            if (root.selected && !found[root.selected]) root.selected = "";
            if (!root.busy && root.moduleId && root.combined.some(a => !found[a])) root.unmerge();
        }
    }

    Process {
        id: modulesProc
        command: ["pactl", "list", "modules"]
        stdout: StdioCollector { id: modulesOut }
        onExited: (code) => {
            if (code !== 0) return;
            let id = "", addresses = [];
            for (const block of modulesOut.text.split("Module #").slice(1)) {
                if (!block.includes("module-combine-sink") || !block.includes("sink_name=bt_combined")) continue;
                id = (block.match(/^(\d+)/) || [])[1] || "";
                const slaves = (block.match(/slaves=([^\s"]+)/) || [])[1] || "";
                addresses = slaves.split(",").map(root.addressFromSink).filter(Boolean);
                break;
            }
            root.moduleId = id;
            root.combined = addresses;
            if (id && !root.busy) root.error = "";
            if (addresses.length) volumeRefresh.restart();
            else root.volumes = ({});
        }
    }

    // Subscribe for changes made by the device's own volume buttons; poll as a fallback.
    Process {
        command: ["pactl", "subscribe"]
        running: BluetoothService.panelOpen && root.combined.length > 0
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("on sink ")) volumeRefresh.restart();
            }
        }
    }

    Timer {
        id: volumeRefresh
        interval: 150
        onTriggered: {
            if (!volumesProc.running && !volumeAction.running && root.combined.length) volumesProc.running = true;
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: BluetoothService.panelOpen && root.combined.length > 0
        onTriggered: volumeRefresh.restart()
    }

    Process {
        id: volumesProc
        command: ["pactl", "list", "sinks"]
        stdout: StdioCollector { id: volumesOut }
        onExited: (code) => {
            if (code !== 0) return;
            const next = {};
            for (const block of volumesOut.text.split("Sink #").slice(1)) {
                const name = (block.match(/^\s*Name: ([^\s]+)/m) || [])[1] || "";
                const address = root.addressFromSink(name);
                if (!root.combined.includes(address)) continue;
                const value = (block.match(/^\s*Volume:.*?\s(\d+)%/m) || [])[1];
                if (value !== undefined) next[address] = Number(value);
            }
            root.volumes = next;
        }
    }

    Process {
        id: volumeAction
        stderr: StdioCollector { id: volumeErr }
        onExited: (code) => {
            if (code !== 0) root.error = volumeErr.text.trim() || "Volume change failed";
            if (root.volumeQueue.length) root.runVolumeQueue();
            else volumeRefresh.restart();
        }
    }

    Timer {
        id: defaultDelay
        interval: 800
        onTriggered: root.runAction(["pactl", "set-default-sink", "bt_combined"], "set-default")
    }

    Process {
        id: action
        stdout: StdioCollector { id: actionOut }
        stderr: StdioCollector { id: actionErr }
        onExited: (code) => {
            const current = root.step;
            if (code !== 0) {
                root.error = actionErr.text.trim() || "Audio mix failed";
                if (current === "set-default" && root.moduleId) {
                    root.unmerge();
                    return;
                }
                root.busy = false;
                root.step = "";
                root.refresh();
                return;
            }
            if (current === "read-default") {
                root.previousDefault = actionOut.text.trim();
                const names = root.pending.map(a => root.sinks[a]);
                if (names.some(n => !n)) {
                    root.error = "Audio output disconnected";
                    root.busy = false;
                    root.refresh();
                    return;
                }
                root.runAction(["pactl", "load-module", "module-combine-sink",
                    "sink_name=bt_combined", "slaves=" + names.join(",")], "load");
                return;
            } else if (current === "load") {
                root.moduleId = actionOut.text.trim();
                root.combined = root.pending;
                defaultDelay.start();
                return;
            } else if (current === "unload") {
                // After a shell restart the original default is unknown: fall back to the first Bluetooth output.
                const fallback = root.previousDefault || root.sinks[root.combined[0]];
                root.moduleId = "";
                root.combined = [];
                root.previousDefault = "";
                root.pending = [];
                if (fallback) {
                    root.runAction(["pactl", "set-default-sink", fallback], "restore");
                    return;
                }
            }
            root.busy = false;
            root.step = "";
            root.refresh();
        }
    }

    Connections {
        target: BluetoothService
        function onPanelOpenChanged() {
            if (BluetoothService.panelOpen) root.refresh();
            else root.selected = "";
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: BluetoothService.panelOpen
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "bluetoothAudio"
        function refresh() { root.refresh(); }
        function isCombined(): bool { return root.moduleId !== ""; }
        function toggle(address: string) { root.toggle(address); }
        function setVolume(address: string, percent: int) { root.setVolume(address, percent); }
        function volume(address: string): int {
            const value = root.volumes[String(address).toUpperCase()];
            return value === undefined ? -1 : value;
        }
    }
}
