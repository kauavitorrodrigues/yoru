import QtQuick
import qs.services
import "../../common"

Item {
    id: root

    property bool minimal: false

    implicitWidth: minimal ? rowLayout.implicitWidth : columnLayout.implicitWidth
    implicitHeight: minimal ? rowLayout.implicitHeight : columnLayout.implicitHeight

    Column {
        id: columnLayout

        visible: !root.minimal
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

    Row {
        id: rowLayout

        visible: root.minimal
        spacing: 6

        TrackMarqueeText {
            text: PlayerService.title || "Unknown Title"
            color: Appearance.colors.textPrimary
            fontBold: true
            maxWidth: 120
        }

        TrackMarqueeText {
            text: PlayerService.artist || "Unknown Artist"
            color: Appearance.colors.textSecondary
            fontSize: Appearance.fonts.sizes.sm
            maxWidth: 120
        }

    }

}
