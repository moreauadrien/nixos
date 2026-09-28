import Quickshell
import Quickshell.Wayland
import QtQuick

import "../services"

// Popup ancré sous un widget de la barre, réutilisable par tous les modules.
// - anchorItem : le widget déclencheur ; le popup s'aligne sous lui, bord
//   droit sur bord droit (même formule que Tooltip.qml).
// - Contenu injecté via la propriété par défaut ; l'appelant dimensionne le
//   popup via contentWidth / contentHeight (properties simples — pas d'alias
//   vers implicit*: la chaîne d'indirection gardait des tailles stale et le
//   contenu débordait du cadre).
// - Fermeture : clic extérieur (PopupManager) ou Esc.
// - Exclusivité : ouvrir un popup ferme le précédent (PopupManager).
PanelWindow {
    id: root

    required property Item anchorItem
    property real contentWidth: 0
    property real contentHeight: 0
    default property alias contentData: content.data

    // « closed » et « opened » sont déjà pris par PanelWindow/QsWindow.
    signal popupOpened()
    signal popupClosed()

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // PanelWindow est visible par défaut — sans ça, le popup s'ouvre au
    // lancement de quickshell.
    visible: false

    anchors {
        top: true
        right: true
    }

    implicitWidth: contentWidth + 24
    implicitHeight: contentHeight + 20

    margins.top: Theme.barHeight + 4
    // Recalculé impérativement à chaque open() (voir updateAnchorMargins) :
    // un binding sur mapToItem() évalué au démarrage — avant le layout de la
    // barre et le chargement de la police — donnait une marge fausse et le
    // popup s'ouvrait hors écran, invisible.
    margins.right: 8
    function open() {
        // Tue le préchauffage s'il est en cours : la vraie ouverture prime.
        root.warmed = true;
        warmStart.stop();
        warmEnd.stop();
        updateAnchorMargins();
        PopupManager.open(root);
        root.popupOpened();
    }

    function updateAnchorMargins() {
        if (!anchorItem || !root.screen) {
            margins.right = 8;
            return;
        }
        const anchorRight = anchorItem.mapToItem(null, anchorItem.width, 0).x;
        margins.right = Math.max(8, root.screen.width - anchorRight);
    }

    function close() {
        if (!root.visible)
            return;
        root.visible = false;
        PopupManager.notifyClosed(root);
        root.popupClosed();
    }

    // --- préchauffage ---------------------------------------------------------
    // La première cartographie d'une surface layer-shell produit fréquemment
    // une ou deux frames avec un buffer mal dimensionné (flash au premier
    // open après le lancement de quickshell). On mappe donc la fenêtre une
    // fois au démarrage, contenu invisible, puis on la démappe : les opens
    // suivants remapent une surface déjà établie, sans flash.
    property bool warmed: false

    Timer {
        id: warmStart

        interval: 500
        onTriggered: root.visible = true
    }

    Timer {
        id: warmEnd

        interval: 150
        onTriggered: {
            // Si l'utilisateur a ouvert le popup pendant le préchauffage
            // (warmed déjà true via open()), on ne ferme surtout pas.
            if (!root.warmed) {
                root.visible = false;
                root.warmed = true;
            }
        }
    }

    Component.onCompleted: warmStart.restart()

    Rectangle {
        id: frame

        anchors.fill: parent
        opacity: root.warmed ? 1 : 0
        radius: 8
        color: Theme.background
        border.color: Theme.accent
        border.width: 1

        Item {
            id: content

            anchors.centerIn: parent
            width: root.contentWidth
            height: root.contentHeight
            focus: true
            Keys.onEscapePressed: root.close()
        }
    }
}