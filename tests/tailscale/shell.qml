import Quickshell
import QtQuick
import "components"
import "services"

Scope {
    id: root
    property int step: 0
    property int ticks: 0

    // Instantiate the real panel as well as the service to catch QML binding errors.
    TailscalePanel { }

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
                root.check(service.exitNodes.length === 2, "only exit-capable peers");
                root.check(service.peers[0].Online, "online peers first");
                root.check(service.name(service.peers[0]) === "exit", "MagicDNS name");
                root.check(service.ip(service.peers[0]) === "100.64.0.2", "IPv4 address");
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
                service.data = saved;
                service.selectExit("online");
                root.check(service.busy, "exit selection starts command");
                service.selectExit(""); // Must be ignored while the first command runs.
                break;
            }
            case 1:
                service.selectExit("");
                break;
            case 2:
                service.toggle();
                break;
            case 3:
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
