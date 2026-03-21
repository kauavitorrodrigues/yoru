import QtQuick
import qs.services

Row {
    id: root

    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 24

    TrackControlButton {
        iconName: "⏮"
        enabled: PlayerService.activePlayer?.canGoPrevious ?? false
        onClicked: PlayerService.previous()
    }

    TrackControlButton {
        iconName: PlayerService.isPlaying ? "⏸" : "▶"
        enabled: PlayerService.activePlayer?.canTogglePlaying ?? false
        onClicked: PlayerService.playPause()
    }

    TrackControlButton {
        iconName: "⏭"
        enabled: PlayerService.activePlayer?.canGoNext ?? false
        onClicked: PlayerService.next()
    }
}