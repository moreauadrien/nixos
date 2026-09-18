import QtQuick
import "../services"

Text {
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.weight: Theme.fontWeight
    font.pixelSize: Theme.fontSize
    text: Time.time
}
