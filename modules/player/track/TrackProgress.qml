import QtQuick
import qs.services
import qs.modules.common.functions

Item {
    id: root

    readonly property var player: PlayerService.activePlayer
    readonly property real pos: player ? player.position : 0
    readonly property real len: player ? player.length : 0

    implicitWidth: parent.width
    implicitHeight: 4

    Timer {
        interval: 1000
        repeat: true
        running: PlayerService.isPlaying
        onTriggered: {
            if (PlayerService.activePlayer)
                PlayerService.activePlayer.positionChanged();

        }
    }

    Text {
        anchors {
            left: parent.left
            verticalCenter: bar.verticalCenter
        }
        text: DateUtils.formatTime(PlayerService.activePlayer?.position ?? 0)
        color: "white"
        font.pixelSize: 12
        font.bold: true
    }

    Item {
        id: bar
        height: 5
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 40
            rightMargin: 40
            verticalCenter: parent.verticalCenter
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.15)
            radius: 2
        }

        Rectangle {
            readonly property var player: PlayerService.activePlayer
            readonly property real pos: player ? player.position : 0
            readonly property real len: player ? player.length : 0

            width: len > 0 ? parent.width * (pos / len) : 0
            height: parent.height
            color: "white"
            radius: 2

            Behavior on width {
                NumberAnimation { duration: 900; easing.type: Easing.Linear }
            }
        }
    }

    Text {
        anchors {
            right: parent.right
            verticalCenter: bar.verticalCenter
        }
        text: DateUtils.formatTime(PlayerService.activePlayer?.length ?? 0)
        color: Qt.rgba(1, 1, 1, 0.5)
        font.pixelSize: 12
        font.bold: true
    }

}
