import QtQuick
import QtQuick.Controls
import qs.services
import "../../common"

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
        color: root.hovered ? Appearance.colors.hoverStrong : Appearance.colors.hoverSoft
        radius: 5

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.fast
            }

        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.animation.instant
        }

    }

    contentItem: Text {
        text: root.iconName
        font.family: Appearance.fonts.primary
        font.pixelSize: root.iconSize
        color: root.enabled ? Appearance.colors.textPrimary : Appearance.colors.textDisabled
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

}
