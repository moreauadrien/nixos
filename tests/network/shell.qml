import Quickshell
import QtQuick
import "components"
import "services"

Scope {
    id: root
    property int step: 0
    property int ticks: 0
    NetworkPanel { id: panel }
    function findItem(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = findItem(child, name);
            if (found) return found;
        }
        return null;
    }
    function check(condition, message) {
        if (!condition) { console.error("FAIL: " + message); Qt.exit(1); }
    }
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (++root.ticks > 150) { console.error("FAIL: timeout"); Qt.exit(1); return; }
            const service = NetworkService;
            if (!service.available || service.busy) return;
            switch (root.step++) {
            case 0: {
                root.check(service.connected && service.active.type === "ethernet", "wired default route");
                root.check(service.wifiEnabled && service.ethernet.length === 1 && service.networks[0].active, "simultaneous wifi and ethernet");
                root.check(service.networks[0].active, "active network sorted first");
                const saved = service.data;
                service.data = {wifiEnabled: false, active: saved.active};
                root.check(service.connected, "wifi off does not disconnect ethernet");
                service.data = {wifiEnabled: false};
                root.check(!service.connected && service.status === "WI-FI OFF", "disconnected state");
                service.data = saved;
                panel.requestPassword(service.networks[0]);
                const field = root.findItem(panel, "networkPassword");
                root.check(field && field.echoMode === TextInput.Password, "password masked initially");
                field.text = "discard-me";
                panel.cancelPassword();
                root.check(field.text === "" && panel.passwordNetwork === null, "password cleared on cancel");
                panel.requestPassword(service.networks[0]);
                field.text = "test-secret";
                panel.submitPassword();
                root.check(field.text === "" && panel.passwordNetwork === null, "password cleared on submit");
                root.check(service.busy, "connection begins");
                service.scan(); // Ignored while connecting.
                break;
            }
            case 1: service.run({action: "wired", interface: "eth0"}); break;
            case 2: service.disconnect("wlan0"); break;
            case 3: service.forget("wifi-uuid"); break;
            case 4: service.run({action: "fail"}); break;
            case 5:
                root.check(service.error === "Permission denied", "backend error displayed");
                panel.cancelPassword();
                service.connect(service.networks[0]);
                break;
            case 6:
                console.log("PASS: Network service and panel");
                Qt.quit();
            }
        }
    }
}
