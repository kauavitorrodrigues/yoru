import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string icon: ""
    property color iconColor: '#ffffff'
    property string label: ""
    property color labelColor: "#c4c4c4"
    property real hPadding: 20

    implicitWidth: row.implicitWidth + hPadding * 2
    implicitHeight: row.implicitHeight + 15

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.08, 0.07, 0.07)
        radius: 15
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: root.iconColor
        }

        Text {
            visible: root.label !== ""
            text: root.label
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: root.labelColor
        }
    }
}
