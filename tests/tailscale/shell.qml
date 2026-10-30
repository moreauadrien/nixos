import Quickshell
import QtQuick
import "components"
import "services"

Scope {
    id: root
    property int step: 0
    property int ticks: 0
    readonly property var copyPeer: ({ HostName: "localhost", DNSName: "bicycle.tailxxx.ts.net.", TailscaleIPs: ["fd7a::4", "100.64.0.4"] })

    // Instantiate the real panel as well as the service to catch QML binding errors.
    TailscalePanel { id: panel }
    TailscaleIcon { id: icon }
    PanelSwitch {
        id: switchPreview
        active: true
        property int requests: 0
        onToggleRequested: requests++
    }

    function luminance(color) {
        const rgb = [color.r, color.g, color.b].map(value =>
            value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4));
        return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
    }

    function findItem(item, objectName) {
        if (item.objectName === objectName) return item;
        for (const child of item.children || []) {
            const found = findItem(child, objectName);
            if (found) return found;
        }
        return null;
    }

    function check(condition, message) {
        if (!condition) {
            console.error("FAIL: " + message);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (++root.ticks > 100) {
                console.error("FAIL: test timed out");
                Qt.exit(1);
                return;
            }
            if (!TailscaleService.available || TailscaleService.busy) return;
            const service = TailscaleService;
            switch (root.step++) {
            case 0: {
                root.check(service.connected, "running state");
                const track = switchPreview.indicator;
                const thumb = track.children[0];
                const contrast = (root.luminance(thumb.color) + 0.05) / (root.luminance(track.color) + 0.05);
                root.check(contrast >= 3, "switch thumb contrast at least 3:1");
                switchPreview.checked = false;
                switchPreview.toggled();
                root.check(switchPreview.requests === 1 && switchPreview.checked, "switch requests state without overriding service");
                switchPreview.active = false;
                root.check(!switchPreview.checked, "shared switch follows off state");
                switchPreview.active = true;
                root.check(switchPreview.checked, "shared switch binding survives interaction");
                const picker = root.findItem(panel, "exitNodePicker");
                root.check(picker.background.color.a === 0 && picker.background.border.width === 0, "exit picker has no idle selection frame");
                const control = root.findItem(panel, "tailscaleSwitch");
                root.check(control !== null && control.checked && control.enabled, "connected switch");
                const dots = icon.children.filter(child => child.width === icon.iconSize * 0.24);
                root.check(dots.length === 9 && dots.filter(dot => dot.opacity === 1).length === 4, "Tailscale dot grid");
                root.check(service.exitNodes.length === 2, "only exit-capable peers");
                root.check(service.peers[0].Online, "online peers first");
                root.check(service.name(service.peers[0]) === "exit", "MagicDNS name");
                root.check(service.ip(service.peers[0]) === "100.64.0.2", "IPv4 address");
                root.check(service.name(root.copyPeer) === "bicycle", "copy short MagicDNS name");
                root.check(service.domain(root.copyPeer) === "bicycle.tailxxx.ts.net", "copy domain without trailing dot");
                root.check(service.ip(root.copyPeer) === "100.64.0.4", "IPv4 selected independently of address order");
                root.check(service.ip(root.copyPeer, true) === "fd7a::4", "copy IPv6");
                root.check(service.ip({}, true) === "" && service.domain({}) === "", "missing copy values disabled");
                service.copy("");
                service.copy(service.name(root.copyPeer));
                service.selectExit("offline");
                root.check(!service.busy, "offline exit rejected");
                service.selectExit("unknown");
                root.check(!service.busy, "unknown exit rejected");
                const saved = service.data;
                service.data = { BackendState: "NeedsLogin", AuthURL: "https://login.tailscale.com/a/test" };
                root.check(!service.connected && service.status === "LOGIN REQUIRED", "logged-out state");
                root.check(service.authUrl !== "", "browser login available");
                service.data = { BackendState: "Stopped" };
                root.check(!service.connected && service.exitNodes.length === 0, "stopped state and missing peers");
                root.check(!control.checked, "disconnected switch");
                service.data = saved;
                const hostname = root.findItem(panel, "tailscaleHostname");
                const titleY = hostname.mapToItem(panel, 0, 0).y;
                service.selectExit("online");
                root.check(hostname.mapToItem(panel, 0, 0).y === titleY, "hostname stays fixed while working");
                root.check(service.busy, "exit selection starts command");
                root.check(!control.enabled, "switch disabled during commands");
                service.selectExit(""); // Must be ignored while the first command runs.
                break;
            }
            case 1:
                service.copy(service.domain(root.copyPeer));
                service.selectExit("");
                break;
            case 2:
                service.copy(service.ip(root.copyPeer));
                service.toggle();
                break;
            case 3:
                service.copy(service.ip(root.copyPeer, true));
                service.data = { BackendState: "Stopped" };
                service.toggle();
                break;
            case 4:
                service.run(["fail"]);
                break;
            case 5:
                root.check(service.error.includes("permission denied"), "command errors shown");
                service.data = { BackendState: "Running", ExitNodeStatus: { ID: "offline" } };
                root.check(service.exitId === "offline", "selected offline exit preserved");
                console.log("PASS: Tailscale service and panel");
                Qt.quit();
            }
        }
    }
}
