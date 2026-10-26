import QtQuick

import "../services"

Text {
    id: root

    readonly property bool connected: Network.anyConnected

    text: Network.pillIcon
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    // Busy est une propriété locale : l'ancre onBusyChanged existe sinon pas.
    readonly property bool busy: Network.busy

    SequentialAnimation on opacity {
        running: root.busy
        loops: Animation.Infinite

        NumberAnimation {
            from: 1
            to: 0.35
            duration: 600
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            from: 0.35
            to: 1
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }
}
