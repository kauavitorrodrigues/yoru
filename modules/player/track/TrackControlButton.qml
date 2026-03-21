import QtQuick
import QtQuick.Controls
import qs.services

Button {
    id: root

    required property string iconName
    property int iconSize: 20

    implicitWidth: iconSize + 16
    implicitHeight: iconSize + 16
    opacity: root.pressed ? 0.6 : 1

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }

    background: Rectangle {
        color: root.hovered ? Qt.rgba(0.32, 0.32, 0.32, 0.75) : Qt.rgba(0.24, 0.24, 0.24, 0.75)
        radius: 5

        Behavior on color {
            ColorAnimation {
                duration: 120
            }

        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: 80
        }

    }

    contentItem: Text {
        text: root.iconName
        font.pixelSize: root.iconSize
        color: root.enabled ? "white" : Qt.rgba(1, 1, 1, 0.3)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

}
