import Quickshell
import QtQuick
import "../common"
import "state"
import "../../services"

PanelWindow {
    id: root

    // Pin to a single screen: a plain PanelWindow with no `screen` set
    // auto-instantiates once per connected monitor (like TopBar/Dock
    // intentionally do), which for a modal picker meant N independent
    // overlays, each running its own scan/thumbnail/GIF-decode pipeline
    // concurrently and fighting over the same WallpaperState.visible flag.
    screen: Quickshell.screens[0]

    // Fixed size, no anchors: compositor centers this on the screen.
    // aboveWindows places it on the overlay layer above all other surfaces.
    implicitWidth: Appearance.sizing.wallpaper.overlayWidth
    implicitHeight: Appearance.sizing.wallpaper.overlayHeight
    aboveWindows: true
    focusable: true
    color: Appearance.colors.transparent

    // The window is only kept mapped (visible) for the duration of the fade
    // animation below; otherwise the compositor unmaps it immediately on
    // close and the fade-out Behavior never gets a chance to render.
    visible: root._mapped
    property bool _mapped: false

    readonly property string resolvedDirectory: Settings.modules.wallpaper.directory !== "" ? Settings.modules.wallpaper.directory : (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    readonly property string resolvedCacheDir: Settings.modules.wallpaper.cacheDir !== "" ? Settings.modules.wallpaper.cacheDir : ((Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yoru/wallpaper-thumbnails")

    WallpaperModel {
        id: wallpaperModel
        directory: root.resolvedDirectory
        cacheDir: root.resolvedCacheDir
        onWallpaperApplied: WallpaperState.visible = false
        onReadyForSelection: (index) => {
            if (index >= 0)
                carousel.selectInitial(index);
        }
    }

    Connections {
        target: WallpaperState
        function onVisibleChanged() {
            if (WallpaperState.visible) {
                // Cancel a pending unmap from a close that got reversed
                // before the fade-out finished, otherwise it fires later
                // and yanks the window away while it should stay open.
                unmapTimer.stop();
                root._mapped = true;
                wallpaperModel.startScan();
            } else {
                unmapTimer.restart();
            }
        }
    }

    Timer {
        id: unmapTimer
        // Small margin over the opacity Behavior's duration so the fade-out
        // is guaranteed to finish rendering before the window unmaps.
        interval: Appearance.animation.fast + 30
        onTriggered: root._mapped = false
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.shellSurfaceElevated
        radius: Appearance.sizing.wallpaper.overlayRadius
        opacity: WallpaperState.visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.fast
                easing.type: Appearance.animationCurves.outCubic
            }
        }

        WallpaperCarousel {
            id: carousel
            anchors.centerIn: parent
            width: parent.width - 40
            height: Appearance.sizing.wallpaper.itemHeight
            wallpaperModel: wallpaperModel
            onApplyRequested: (index) => wallpaperModel.applyWallpaper(index)
            onCloseRequested: WallpaperState.visible = false
        }
    }
}
