// services/Tooltip.qml (ou components/)
import Quickshell
import Quickshell.Wayland
import QtQuick

import "../services"
import "../config.js" as Config

PanelWindow {
    id: root

    property Item anchorItem
    property string text: ""
    property int barHeight: Config.bar.height

    visible: false
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tooltip"

    anchors {
        top: true
        right: true
    }

    implicitWidth: rect.implicitWidth
    implicitHeight: rect.implicitHeight

    margins.top: Config.bar.height + 4
    margins.right: {
        if (!anchorItem)
            return 8;
        // position réelle de l'ancre dans l'écran, plus de calcul supposé
        const pos = anchorItem.mapToItem(null, anchorItem.width / 2, 0);
        return Math.max(8, root.screen.width - pos.x - implicitWidth / 2);
    }

    Rectangle {
        id: rect
        anchors.centerIn: parent
        implicitWidth: label.implicitWidth + 16
        implicitHeight: label.implicitHeight + 10
        radius: 6
        color: Config.colors.background
        border.color: Config.colors.textMuted
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Config.colors.text
            font.family: Config.bar.fontFamily
            font.pixelSize: Config.bar.fontSize
        }
    }

    // logique hover-delay + anti-flicker encapsulée ici
    property bool wantShow: false
    Timer {
        id: showDelay
        interval: 300
        onTriggered: root.visible = true
    }
    Timer {
        id: hideLinger
        interval: 150
        onTriggered: root.visible = false
    }
    onWantShowChanged: {
        if (wantShow) {
            hideLinger.stop();
            showDelay.start();
        } else {
            showDelay.stop();
            hideLinger.start();
        }
    }
}
