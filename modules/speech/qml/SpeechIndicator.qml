import QtQuick
import "../../common"
import "../state"

Item {
    id: root

    property real hPadding: 20

    implicitWidth: waveForm.implicitWidth + hPadding * 2
    implicitHeight: waveForm.implicitHeight + 15

    opacity: 0

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.shellSurface
        radius: height / 2
    }

    CenteredBars {
        id: waveForm

        anchors.centerIn: parent
        amplitudes: SpeechState.micAmplitudes
        barColor: Appearance.colors.textPrimary
        maxBarHeight: 26
        barWidth: 4
        spacing: 3
    }
}
