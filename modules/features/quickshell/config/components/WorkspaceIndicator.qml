import Quickshell.Hyprland
import QtQuick

import "../services"

Text {
    text: Hyprland.focusedWorkspace?.id ?? ""
    color: Theme.colorText
    font.family: Theme.barFontFamily
    font.weight: Theme.barFontWeight
    font.pixelSize: Theme.barFontSize
}
