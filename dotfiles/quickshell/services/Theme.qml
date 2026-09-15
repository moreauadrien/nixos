pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property color foreground: "#cdd6f4"
    property color background: "#181824"
    property color accent: "#7aa2f7"
    property color muted: "#414868"
    property color urgent: "#f7768e"

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontWeight: 400
    property int fontSize: 16

    property int barHeight: 30
}
