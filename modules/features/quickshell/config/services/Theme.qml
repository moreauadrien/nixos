pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Palette brute (à n'utiliser qu'ici)
    readonly property color paletteBg: "#1a1b26"
    readonly property color paletteBgDark: "#32344a"
    readonly property color paletteFg: "#a9b1d6"
    readonly property color paletteGray: "#444b6a"

    readonly property color paletteBlue: "#7aa2f7"
    readonly property color paletteBlueBright: "#7da6ff"
    readonly property color paletteCyan: "#449dab"
    readonly property color paletteCyanBright: "#0db9d7"
    readonly property color paletteGreen: "#9ece6a"
    readonly property color paletteGreenBright: "#b9f27c"
    readonly property color paletteMagenta: "#ad8ee6"
    readonly property color paletteMagentaBright: "#bb9af7"
    readonly property color paletteRed: "#f7768e"
    readonly property color paletteRedBright: "#ff7a93"
    readonly property color paletteWhite: "#787c99"
    readonly property color paletteWhiteBright: "#acb0d0"
    readonly property color paletteYellow: "#e0af68"
    readonly property color paletteYellowBright: "#ff9e64"

    // Rôles (à utiliser dans les composants)
    readonly property color colorBackground: paletteBg
    readonly property color colorSurface: paletteBgDark

    readonly property color colorText: paletteFg
    readonly property color colorTextMuted: paletteGray
    readonly property color colorTextSubtle: paletteWhite

    readonly property color colorAccent: paletteBlue
    readonly property color colorAccentBright: paletteBlueBright

    readonly property color colorSuccess: paletteGreen
    readonly property color colorSuccessBright: paletteGreenBright

    readonly property color colorWarning: paletteYellow
    readonly property color colorWarningBright: paletteYellowBright

    readonly property color colorError: paletteRed
    readonly property color colorErrorBright: paletteRedBright

    readonly property color colorInfo: paletteCyan
    readonly property color colorInfoBright: paletteCyanBright

    readonly property color colorHighlight: paletteMagenta
    readonly property color colorHighlightBright: paletteMagentaBright

    // Barre
    readonly property string barFontFamily: "JetBrainsMono Nerd Font"
    readonly property int barFontWeight: 400
    readonly property int barFontSize: 16
    readonly property int barHeight: 30
}
