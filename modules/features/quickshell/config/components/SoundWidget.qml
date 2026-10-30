import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "../services"

Text {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.ready && sink.audio !== null
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available && sink.audio.muted

    text: !available || muted ? "󰖁" : volume <= 0 ? "󰕿" : volume < 0.5 ? "󰖀" : "󰕾"
    color: Theme.colorText
    font.family: Theme.barFontFamily
    font.pixelSize: Theme.barFontSize

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: tooltip.wantShow = containsMouse
        onWheel: wheel => {
            if (!root.available) {
                wheel.accepted = false;
                return;
            }
            const steps = wheel.angleDelta.y / 120;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + steps * 0.05));
            wheel.accepted = true;
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.available) root.sink.audio.muted = !root.muted;
                return;
            }
            if (popup.visible) {
                popup.visible = false;
                return;
            }
            if (!root.QsWindow.window) return;
            const right = root.mapToItem(null, root.width, 0).x;
            popup.margins.right = Math.max(8, root.QsWindow.window.screen.width - right);
            popup.visible = true;
        }
    }

    Tooltip {
        id: tooltip
        anchorItem: root
        text: !root.available ? "No audio output" : root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
    }

    PanelWindow {
        screen: root.QsWindow.window?.screen ?? null
        visible: popup.visible
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
        screen: root.QsWindow.window?.screen ?? null
        visible: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors { top: true; right: true }
        margins.top: Theme.barHeight + 4
        margins.right: 8
        implicitWidth: 424
        implicitHeight: Math.min(panel.implicitHeight + 20, (screen?.height ?? 800) - Theme.barHeight - 20)

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.colorBackground
            border.color: Theme.colorAccent
            border.width: 1
        }
        SoundPanel {
            id: panel
            active: popup.visible
            anchors.fill: parent
            anchors { topMargin: 10; bottomMargin: 10; leftMargin: 12; rightMargin: 12 }
            focus: true
            Keys.onEscapePressed: popup.visible = false
        }
    }
}
