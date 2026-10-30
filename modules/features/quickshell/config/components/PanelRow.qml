import QtQuick
import QtQuick.Controls
import "../services"

AbstractButton {
    id: root
    required property string title
    property string glyph: ""
    property string subtitle: ""
    property string detail: ""
    property bool selected: false
    property alias actions: actions.data
    implicitHeight: subtitle ? 48 : 34
    Accessible.name: title + (subtitle ? ", " + subtitle : "")
    background: Rectangle {
        radius: 4
        color: root.hovered ? Qt.alpha(Theme.colorText, 0.06) : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.colorAccent
    }
    contentItem: Item {
        opacity: root.enabled ? 1 : 0.5
        Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: root.glyph
            color: root.selected ? Theme.colorAccent : Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 16
        }
        Column {
            anchors { left: parent.left; leftMargin: 38; right: detail.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 2
            Text {
                width: parent.width
                text: root.title
                textFormat: Text.PlainText
                color: root.selected ? Theme.colorAccent : Theme.colorText
                font.family: Theme.barFontFamily
                font.pixelSize: 14
                elide: Text.ElideRight
            }
            Text {
                visible: root.subtitle !== ""
                width: parent.width
                text: root.subtitle
                textFormat: Text.PlainText
                color: Theme.colorTextSubtle
                font.family: Theme.barFontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
        Text {
            id: detail
            anchors { right: actions.left; rightMargin: actions.width ? 10 : 0; verticalCenter: parent.verticalCenter }
            text: root.detail
            color: Theme.colorTextSubtle
            font.family: Theme.barFontFamily
            font.pixelSize: 11
        }
        Row {
            id: actions
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 6
        }
    }
}
