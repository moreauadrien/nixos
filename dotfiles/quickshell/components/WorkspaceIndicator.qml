import Quickshell.Hyprland
import QtQuick

import "../services"

Text {
    text: Hyprland.focusedWorkspace?.id ?? ""
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.weight: Theme.fontWeight
    font.pixelSize: Theme.fontSize
}
