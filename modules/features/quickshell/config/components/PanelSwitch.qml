pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../services"

Switch {
    id: root
    property bool active: false
    signal toggleRequested()

    implicitWidth: 44
    implicitHeight: 32
    padding: 0
    spacing: 0
    checked: active
    onToggled: {
        // The service owns the state, including failed or pending requests.
        checked = Qt.binding(() => root.active);
        toggleRequested();
    }
    contentItem: Item {}
    background: Item {}
    indicator: Rectangle {
        anchors.centerIn: parent
        implicitWidth: 44
        implicitHeight: 24
        radius: height / 2
        color: Theme.colorSurface
        border.color: root.active ? Theme.colorAccent : Theme.colorTextMuted

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 6
            height: parent.height + 6
            radius: height / 2
            color: "transparent"
            border.color: Theme.colorAccent
            visible: root.activeFocus
        }
        Rectangle {
            width: 18
            height: 18
            radius: width / 2
            x: root.active ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            color: root.active ? Theme.colorAccent : Theme.colorTextSubtle
            opacity: root.enabled ? 1 : 0.5
            scale: root.down ? 0.9 : 1
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
    }
    HoverHandler { cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
}
