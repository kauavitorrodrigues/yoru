import QtQuick
import qs.services
import "../../common"

Column {
    spacing: 0

    TrackMarqueeText {
        text: PlayerService.title || "Unknown Title"
        color: Appearance.colors.textPrimary
        fontBold: true
    }

    TrackMarqueeText {
        text: PlayerService.artist || "Unknown Artist"
        color: Appearance.colors.textSecondary
        fontSize: Appearance.fonts.sizes.sm
    }

}
