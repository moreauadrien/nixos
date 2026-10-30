import Quickshell
import QtQuick
import "components"
import "services"

Scope {
    id: root
    property int step: 0
    property int ticks: 0
    Window {
        visible: true
        width: 400
        height: 500
        NetworkPanel { id: panel; anchors.fill: parent }
        Item { id: otherFocus }
    }
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
                for (const [signal, glyph] of [[0, "󰤯"], [20, "󰤯"], [21, "󰤟"], [40, "󰤟"],
                    [41, "󰤢"], [60, "󰤢"], [61, "󰤥"], [80, "󰤥"], [81, "󰤨"], [100, "󰤨"]])
                    root.check(service.wifiIcon(signal) === glyph, "Omarchy Wi-Fi signal icon " + signal);
                service.data = Object.assign({}, saved, {active: {interface: "wlan0", type: "wifi"}});
                root.check(service.icon === "󰤢", "bar Wi-Fi icon uses connected access point signal");
                service.data = {wifiEnabled: false, active: saved.active};
                root.check(service.icon === "󰈀", "wired icon independent of Wi-Fi power");
                root.check(service.connected, "wifi off does not disconnect ethernet");
                service.data = {wifiEnabled: false};
                root.check(!service.connected && service.status === "WI-FI OFF" && service.icon === "󰤮", "disconnected state and Omarchy icon");
                service.data = saved;
                panel.requestPassword(service.networks[1]);
                const field = root.findItem(panel, "networkPassword");
                root.check(field && field.echoMode === TextInput.Password, "password masked initially");
                root.check(panel.passwordHost && panel.passwordHost.parent.modelData.ssid === "Other",
                    "password hosted under clicked second network, not list header");
                panel.passwordHost.parent.forceLayout();
                root.check(panel.passwordHost.y >= panel.passwordHost.parent.children[0].height,
                    "password slot follows selected network row");
                field.text = "discard-me";
                field.forceActiveFocus();
                service.data = Object.assign({}, saved, {networks: saved.networks.map(n => Object.assign({}, n, {signal: n.signal - 1}))});
                root.check(root.findItem(panel, "networkPassword") === field && field.text === "discard-me"
                    && panel.passwordHost && panel.passwordHost.parent.modelData.ssid === "Other",
                    "scan refresh preserves shared editor and typed password under same SSID");
                root.check(field.activeFocus, "scan refresh preserves input focus");
                panel.cancelPassword();
                root.check(field.text === "" && panel.passwordNetwork === null, "password cleared on cancel");
                panel.requestPassword(service.networks[0]);
                field.text = "test-secret";
                root.check(field.font.pixelSize === 18 && field.font.letterSpacing === 4 && field.passwordCharacter === "●", "large spaced password dots");
                panel.submitPassword();
                root.check(field.text === "" && panel.passwordNetwork !== null, "secret cleared but editor kept during connection");
                root.check(service.busy && !field.enabled, "connection begins and editing disabled");
                root.check(field.connecting && field.placeholderText === "Connecting…"
                    && field.horizontalAlignment === TextInput.AlignHCenter
                    && field.leftPadding === field.rightPadding, "connecting centered in original input");
                root.check(!root.findItem(panel, "passwordActions").visible
                    && !root.findItem(panel, "connectionFeedback").visible, "no actions or duplicate feedback while input connects");
                root.check(service.connectionMessage === "Connecting to Home: wifi…", "connecting feedback names network");
                service.scan(); // Ignored while connecting.
                const host = panel.passwordHost;
                const viewport = root.findItem(panel, "networkViewport");
                const scroll = viewport.contentY;
                panel.active = false;
                panel.visible = false;
                root.check(panel.passwordHost === host && panel.passwordNetwork !== null && field.text === "",
                    "closing retains pending network and editor without secret");
                panel.visible = true;
                panel.active = true;
                root.check(panel.passwordHost === host && field.connecting && viewport.contentY === scroll,
                    "reopening restores connecting field under same row and scroll position");
                panel.active = false;
                panel.visible = false;
                break;
            }
            case 1:
                root.check(panel.passwordNetwork === null && service.connectionMessage === "Connected to Home: wifi", "success while hidden clears connecting editor");
                panel.visible = true;
                panel.active = true;
                service.run({action: "wired", interface: "eth0"});
                break;
            case 2: service.disconnect("wlan0"); break;
            case 3: service.forget("wifi-uuid"); break;
            case 4: service.run({action: "fail"}); break;
            case 5:
                root.check(service.error === "Permission denied", "backend error displayed");
                panel.cancelPassword();
                service.connect(service.networks[0]);
                break;
            case 6:
                service.connect(service.networks[0], "wrong-secret");
                break;
            case 7: {
                const field = root.findItem(panel, "networkPassword");
                root.check(service.error !== "" && service.connectionMessage.includes(service.error)
                    && service.connectionMessage.includes("Retype the password"), "actionable failed connection feedback");
                const feedback = root.findItem(panel, "connectionFeedback");
                const duplicate = root.findItem(panel, "networkError");
                root.check(duplicate.text === "", "connection error not duplicated below list");
                root.check(feedback.text === service.connectionMessage, "single feedback includes connection error");
                root.check(panel.passwordNetwork !== null && field.text === "" && field.enabled, "failure reopens empty editable password");
                root.check(!field.connecting && field.placeholderText !== "Connecting…"
                    && field.horizontalAlignment === TextInput.AlignLeft, "failure restores normal password input");
                field.text = "corrected-secret";
                panel.submitPassword();
                break;
            }
            case 8:
                root.check(service.error === "" && panel.passwordNetwork === null, "retry succeeds and clears error");
                panel.requestPassword(service.networks[0]);
                service.connect(service.networks[0], "wrong-secret");
                panel.active = false;
                panel.visible = false;
                otherFocus.forceActiveFocus();
                break;
            case 9:
                root.check(panel.passwordNetwork !== null && !panel.active && !panel.visible,
                    "failure while hidden keeps retry state without opening panel");
                const field = root.findItem(panel, "networkPassword");
                root.check(field.text === "" && otherFocus.activeFocus, "hidden retry contains no secret and does not steal focus");
                panel.visible = true;
                panel.active = true;
                root.check(panel.passwordHost !== null && field.enabled && !field.connecting
                    && service.connectionMessage.includes("Retype the password"), "reopening after failure restores editable retry and error");
                console.log("PASS: Network service and panel");
                Qt.quit();
            }
        }
    }
}
