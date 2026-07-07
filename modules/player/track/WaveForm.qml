import QtQuick
import QtQuick.Controls
import "../../common"

Item {
    id: root

    property var amplitudes: []
    property color barColor: Appearance.colors.textPrimary
    property int maxBarHeight: 20
    property int barWidth: 3
    property int spacing: 2

    width: amplitudes.length * (barWidth + spacing)
    height: maxBarHeight
    onAmplitudesChanged: { repeater.model = root.amplitudes.length; }

    Repeater {
        id: repeater

        model: root.amplitudes.length

        Rectangle {
            width: root.barWidth
            height: Math.max(root.barWidth, root.amplitudes[index] * root.maxBarHeight)
            radius: root.barWidth / 2
            color: root.barColor
            anchors.verticalCenter: parent.verticalCenter
            x: index * (root.barWidth + root.spacing)
        }

    }

}
