// services/Tooltip.qml (ou components/)
import Quickshell
import Quickshell.Wayland
import QtQuick

import "../services"

PanelWindow {
    id: root

    property Item anchorItem   // l'item par rapport auquel se positionner
    property string text: ""
    property int barHeight: Theme.barHeight // pas de constante en dur

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

    margins.top: Theme.barHeight + 4
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
        color: Theme.background
        border.color: Theme.muted
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
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
