pragma ComponentBehavior: Bound
import QtQuick
import "../services"

Item {
    id: root
    property real iconSize: Theme.barFontSize
    property color color: Theme.colorText
    property bool crossed: false
    implicitWidth: iconSize
    implicitHeight: iconSize

    // Like Omarchy, draw the Tailscale mark natively to keep tiny dots sharp.
    Repeater {
        model: 9
        Rectangle {
            required property int index
            width: root.iconSize * 0.24
            height: width
            radius: width / 2
            x: (index % 3) * (root.iconSize - width) / 2
            y: Math.floor(index / 3) * (root.iconSize - height) / 2
            color: root.color
            opacity: [3, 4, 5, 7].includes(index) ? 1 : 0.24
        }
    }
    Rectangle {
        visible: root.crossed
        anchors.centerIn: parent
        width: root.iconSize * 1.22
        height: Math.max(2, root.iconSize * 0.14)
        radius: height / 2
        color: root.color
        rotation: -45
    }
}
