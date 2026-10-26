import QtQuick
import "../services"

Text {
    color: Theme.colorText
    font.family: Theme.barFontFamily
    font.weight: Theme.barFontWeight
    font.pixelSize: Theme.barFontSize
    text: Time.time
}
