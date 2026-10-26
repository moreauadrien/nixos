import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

Text {
    id: root

    text: !BluetoothService.powered ? "󰂲" : BluetoothService.connectedNames.length ? "󰂱" : "󰂯"
    color: Theme.colorText
    font.family: Theme.barFontFamily
    font.pixelSize: Theme.barFontSize

    function openPopup() {
        if (!root.QsWindow.window) return;
        // mapToItem() is not reactive to layout changes: calculate on every open.
        const right = root.mapToItem(null, root.width, 0).x;
        popup.margins.right = Math.max(8, root.QsWindow.window.screen.width - right);
        popup.reveal();
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) BluetoothService.togglePower();
            else if (popup.visible && !popup.warming) popup.visible = false;
            else root.openPopup();
        }
    }

    Connections {
        target: BluetoothService
        function onShowRequested() { root.openPopup(); }
        function onHideRequested() { popup.visible = false; }
    }

    // Outside clicks land on this layer. The popup is on Overlay above it,
    // so clicking the switch or a device never closes the popup first.
    PanelWindow {
        visible: popup.visible && !popup.warming
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea {
            anchors.fill: parent
            onPressed: popup.visible = false
        }
    }

    PanelWindow {
        id: popup
        visible: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors { top: true; right: true }
        margins.top: Theme.barHeight + 4
        margins.right: 8
        implicitWidth: 424
        // Remap at the previous size, then resize once the layer surface is ready.
        property real lastHeight: 0
        property bool sizeFrozen: true
        property bool warming: false
        property bool warmed: false
        implicitHeight: sizeFrozen && lastHeight ? lastHeight : panel.implicitHeight + 20
        function reveal() {
            warmed = true;
            warming = false;
            warmStart.stop();
            warmEnd.stop();
            visible = true;
            BluetoothService.panelOpen = true;
            settle.restart();
            fade.restart();
        }
        onVisibleChanged: {
            if (warming) return;
            BluetoothService.panelOpen = visible;
            if (!visible) {
                lastHeight = height;
                sizeFrozen = true;
                settle.stop();
                card.opacity = 0;
            }
        }
        Component.onCompleted: {
            lastHeight = implicitHeight;
            warmStart.restart();
        }
        Timer {
            id: warmStart
            interval: 500
            onTriggered: {
                if (popup.warmed) return;
                popup.warming = true;
                popup.visible = true;
                warmEnd.restart();
            }
        }
        Timer {
            id: warmEnd
            interval: 150
            onTriggered: {
                if (popup.warming) {
                    popup.visible = false;
                    popup.warming = false;
                    popup.warmed = true;
                }
            }
        }

        Timer {
            id: settle
            interval: 300
            onTriggered: popup.sizeFrozen = false
        }

        Item {
            id: card
            anchors.fill: parent
            clip: true
            opacity: 0
            NumberAnimation {
                id: fade
                target: card
                property: "opacity"
                from: 0
                to: 1
                duration: 100
            }
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.colorBackground
                border.color: Theme.colorAccent
                border.width: 1
            }
            BluetoothPanel {
                id: panel
                width: implicitWidth
                height: implicitHeight
                anchors { top: parent.top; topMargin: 10; left: parent.left; leftMargin: 12 }
                focus: true
                Keys.onEscapePressed: popup.visible = false
            }
        }
    }
}
