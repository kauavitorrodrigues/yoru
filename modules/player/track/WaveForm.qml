import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var amplitudes: []
    property color barColor: '#ffffff'
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
            height: root.amplitudes[index] * root.maxBarHeight
            color: root.barColor
            anchors.bottom: parent.bottom
            x: index * (root.barWidth + root.spacing)
        }

    }

}