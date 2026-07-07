import QtQuick
import "../../common"

Item {
    id: root

    property var amplitudes: []
    property color barColor: Appearance.colors.textPrimary
    property int maxBarHeight: 26
    property int barWidth: 4
    property int spacing: 3

    implicitWidth: amplitudes.length > 0 ? amplitudes.length * (barWidth + spacing) - spacing : 0
    implicitHeight: maxBarHeight

    Repeater {
        model: root.amplitudes.length

        Rectangle {
            width: root.barWidth
            height: Math.max(root.barWidth, root.amplitudes[index] * root.maxBarHeight)
            radius: width / 2
            color: root.barColor
            anchors.verticalCenter: parent.verticalCenter
            x: index * (root.barWidth + root.spacing)

            Behavior on height {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
            }
        }
    }
}
