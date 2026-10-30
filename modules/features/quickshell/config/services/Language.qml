pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string language: "fr_FR"

    readonly property var locale: {
        Qt.locale(root.language);
    }
}
