import QtQuick
import qs.services

Column {
    spacing: 0

    TrackMarqueeText {
        text: PlayerService.title || "Unknown Title"
        color: Qt.rgba(1, 1, 1)
        fontBold: true
    }

    TrackMarqueeText {
        text: PlayerService.artist || "Unknown Artist"
        color: Qt.rgba(0.67, 0.67, 0.67, 0.9)
        fontSize: 12
    }

}