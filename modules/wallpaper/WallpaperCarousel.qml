import QtQuick
import "../common"

ListView {
    id: carousel

    required property var wallpaperModel

    signal applyRequested(int index)
    signal closeRequested()

    readonly property int itemWidth: Appearance.sizing.wallpaper.itemWidth
    readonly property int itemGap: 16
    readonly property int highlightDuration: Appearance.animation.fast

    // Jumps straight to `index` with no highlight/scroll animation, used to
    // pre-select the current wallpaper on open instead of visibly scrolling
    // there from item 0, which gets slow and distracting on large libraries.
    // positionViewAtIndex (rather than just toggling highlightMoveDuration)
    // is what makes this deterministic even when the target delegate isn't
    // realized yet: StrictlyEnforceRange would otherwise defer the range
    // enforcement scroll to the next frame, by which point the animated
    // duration is already back in place.
    function selectInitial(index) {
        carousel.currentIndex = index;
        carousel.positionViewAtIndex(index, ListView.Center);
    }

    orientation: ListView.Horizontal
    snapMode: ListView.SnapToItem
    model: wallpaperModel.wallpapers
    spacing: itemGap
    focus: true
    clip: false
    cacheBuffer: 0
    highlightMoveDuration: highlightDuration
    highlightMoveVelocity: -1

    // Keep the selected item centered in the view
    preferredHighlightBegin: Math.floor((width - itemWidth) / 2)
    preferredHighlightEnd: Math.floor((width + itemWidth) / 2)
    highlightRangeMode: ListView.StrictlyEnforceRange

    Keys.onEscapePressed: carousel.closeRequested()
    Keys.onTabPressed: if (count > 0)
        currentIndex = (currentIndex + 1) % count
    Keys.onBacktabPressed: if (count > 0)
        currentIndex = (currentIndex - 1 + count) % count
    Keys.onRightPressed: if (count > 0)
        currentIndex = (currentIndex + 1) % count
    Keys.onLeftPressed: if (count > 0)
        currentIndex = (currentIndex - 1 + count) % count
    Keys.onReturnPressed: wallpaperModel.applyWallpaper(currentIndex)
    Keys.onEnterPressed: wallpaperModel.applyWallpaper(currentIndex)

    delegate: WallpaperItem {
        distanceFromCenter: Math.abs(index - ListView.view.currentIndex)
        onApplyRequested: (i) => carousel.applyRequested(i)
    }
}
