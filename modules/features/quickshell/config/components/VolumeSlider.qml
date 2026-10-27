import QtQuick
import QtQuick.Controls
import "../services"

Slider {
    id: root
    property bool muted: false
    signal volumeEdited(int percent)

    from: 0
    to: 100
    stepSize: 5
    wheelEnabled: true
    Accessible.name: "Volume"

    // Commit drags on release, but apply keyboard and wheel changes immediately.
    onMoved: { if (!pressed) volumeEdited(Math.round(value)); }
    onPressedChanged: { if (!pressed) volumeEdited(Math.round(value)); }

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth
        height: 4
        radius: 2
        color: Theme.colorTextMuted
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.enabled && !root.muted ? Theme.colorAccent : Theme.colorTextSubtle
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        width: 10
        height: 10
        radius: 5
        color: root.activeFocus ? Theme.colorAccent : Theme.colorText
    }
}
