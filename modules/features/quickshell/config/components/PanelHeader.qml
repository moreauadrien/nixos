import QtQuick
import "../services"

Item {
    id: root
    required property string icon
    required property string title
    required property string subtitle
    property alias actions: actions.data
    implicitHeight: 54

    Text {
        id: symbol
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: root.icon
        color: Theme.colorAccent
        font.family: Theme.barFontFamily
        font.pixelSize: 24
    }
    Column {
        anchors { left: symbol.right; leftMargin: 12; right: actions.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text {
            width: parent.width
            text: root.title
            textFormat: Text.PlainText
            color: Theme.colorAccent
            font.family: Theme.barFontFamily
            font.pixelSize: 18
            font.bold: true
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.subtitle
            textFormat: Text.PlainText
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
            font.letterSpacing: 1
            elide: Text.ElideRight
        }
    }
    Row {
        id: actions
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 12
    }
}
