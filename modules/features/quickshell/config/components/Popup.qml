import Quickshell
import Quickshell.Wayland
import QtQuick

import "../services"

// Popup ancré sous un widget de la barre, réutilisable par tous les modules.
// - anchorItem : le widget déclencheur ; le popup s'aligne sous lui, bord
//   droit sur bord droit (même formule que Tooltip.qml).
// - Contenu injecté via la propriété par défaut ; les tailles implicites du
//   contenu (contentWidth / contentHeight) dimensionnent la fenêtre.
// - Fermeture : clic extérieur (PopupManager) ou Esc.
// - Exclusivité : ouvrir un popup ferme le précédent (PopupManager).
PanelWindow {
    id: root

    required property Item anchorItem
    default property alias contentData: content.data
    property alias contentWidth: content.implicitWidth
    property alias contentHeight: content.implicitHeight

    signal opened()
    signal closed()

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        right: true
    }

    implicitWidth: frame.width
    implicitHeight: frame.height

    margins.top: Theme.barHeight + 4
    margins.right: {
        if (!anchorItem)
            return 8;
        const anchorRight = anchorItem.mapToItem(null, anchorItem.width, 0).x;
        return Math.max(8, root.screen.width - anchorRight);
    }

    function open() {
        PopupManager.open(root);
        root.opened();
    }

    function close() {
        if (!root.visible)
            return;
        root.visible = false;
        PopupManager.notifyClosed(root);
        root.closed();
    }

    Rectangle {
        id: frame

        anchors.centerIn: parent
        implicitWidth: content.width + 24
        implicitHeight: content.height + 20
        radius: 8
        color: Theme.background
        border.color: Theme.accent
        border.width: 1

        Item {
            id: content

            anchors.centerIn: parent
            focus: true
            Keys.onEscapePressed: root.close()
        }
    }
}