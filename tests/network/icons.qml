import Quickshell
import QtQuick
import "components"
import "services"

Scope {
    id: root
    property int step: 0
    property int ticks: 0
    NetworkWidget { id: network }
    SoundWidget { id: sound }
    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            if (++root.ticks > 100) {
                console.error("FAIL: icon animation timeout");
                Qt.exit(1);
                return;
            }
            if (!NetworkService.available) return;
            if (root.step === 0) {
                if (network.color !== sound.color || network.opacity !== 1) {
                    console.error("FAIL: wired icon must match sound color and opacity");
                    Qt.exit(1);
                    return;
                }
                NetworkService.busy = true;
                root.step++;
            } else if (root.step === 1 && network.opacity < 0.8) {
                NetworkService.busy = false;
                root.step++;
            } else if (root.step === 2) {
                if (network.opacity !== 1 || network.color !== sound.color) {
                    console.error("FAIL: busy animation must restore full foreground opacity");
                    Qt.exit(1);
                    return;
                }
                console.log("PASS: Network icon color and opacity");
                Qt.quit();
            }
        }
    }
}
