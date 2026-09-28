pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick

// Exclusivité + clic extérieur pour les popups de la barre.
// Chaque Popup s'enregistre ici à l'ouverture ; ce singleton ferme le popup
// courant si un autre s'ouvre, et héberge le catcher plein écran qui ferme
// au premier clic en dehors du popup.
Singleton {
    id: root

    property Item current: null

    // Catcher : layer Top (sous les popups en Overlay, au-dessus de la barre).
    // Tant qu'un popup est ouvert, tout clic ici le referme — y compris un
    // clic sur l'icône déclencheur (fermer seulement, pas de re-toggle).
    PanelWindow {
        id: catcher

        visible: root.current !== null
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "popup-catcher"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onPressed: root.closeCurrent()
        }
    }

    function open(popup) {
        if (root.current && root.current !== popup)
            root.current.close();
        root.current = popup;
        popup.visible = true;
    }

    function closeCurrent() {
        if (root.current)
            root.current.close();
    }

    function notifyClosed(popup) {
        if (root.current === popup)
            root.current = null;
    }
}