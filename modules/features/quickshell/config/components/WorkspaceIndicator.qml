import Quickshell.Hyprland
import QtQuick

import "../services"
import "../config.js" as Config

Text {
    text: Hyprland.focusedWorkspace?.id ?? ""
    color: Config.colors.text
    font.family: Config.bar.fontFamily
    font.weight: Config.bar.fontWeight
    font.pixelSize: Config.bar.fontSize
}
