pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject fonts
    property QtObject sizing

    animation: QtObject {
        property int instant: Settings.appearance.animation.instant
        property int fast: Settings.appearance.animation.fast
        property int normal: Settings.appearance.animation.normal
        property int medium: Settings.appearance.animation.medium
        property int slow: Settings.appearance.animation.slow
        property int playerProgress: Settings.appearance.animation.playerProgress
        property int marqueePause: Settings.appearance.animation.marqueePause
    }

    animationCurves: QtObject {
        property int linear: Settings.appearance.animationCurves.linear
        property int inOutQuad: Settings.appearance.animationCurves.inOutQuad
        property int inCubic: Settings.appearance.animationCurves.inCubic
        property int outCubic: Settings.appearance.animationCurves.outCubic
    }

    fonts: QtObject {
        property string primary: Settings.appearance.fonts.primary
        property QtObject sizes: QtObject {
            property int xs: Settings.appearance.fonts.sizes.xs
            property int sm: Settings.appearance.fonts.sizes.sm
            property int md: Settings.appearance.fonts.sizes.md
            property int base: Settings.appearance.fonts.sizes.base
        }
    }

    colors: QtObject {
        property color transparent: Settings.appearance.colors.transparent

        property color shellSurface: Settings.appearance.colors.shellSurface
        property color shellSurfaceElevated: Settings.appearance.colors.shellSurfaceElevated

        property color textPrimary: Settings.appearance.colors.textPrimary
        property color textSecondary: Settings.appearance.colors.textSecondary
        property color textMuted: Settings.appearance.colors.textMuted
        property color textDisabled: Settings.appearance.colors.textDisabled
        property color textOnLight: Settings.appearance.colors.textOnLight

        property color stateDanger: Settings.appearance.colors.stateDanger

        property color hoverSoft: Settings.appearance.colors.hoverSoft
        property color hoverStrong: Settings.appearance.colors.hoverStrong

        property color indicatorActive: Settings.appearance.colors.indicatorActive
        property color indicatorInactive: Settings.appearance.colors.indicatorInactive

        property color cardPlaceholder: Settings.appearance.colors.cardPlaceholder
        property color scrim: Settings.appearance.colors.scrim
    }

    sizing: QtObject {
        property QtObject dock: QtObject {
            property int panelHeight: Settings.appearance.sizing.dock.panelHeight
            property int bottomMargin: Settings.appearance.sizing.dock.bottomMargin
            property int radius: Settings.appearance.sizing.dock.radius
            property QtObject padding: QtObject {
                property int top: Settings.appearance.sizing.dock.padding.top
                property int bottom: Settings.appearance.sizing.dock.padding.bottom
                property int left: Settings.appearance.sizing.dock.padding.left
                property int right: Settings.appearance.sizing.dock.padding.right
            }
            property int previewRadius: Settings.appearance.sizing.dock.previewRadius
            property QtObject icons: QtObject {
                property int size: Settings.appearance.sizing.dock.icons.size
                property int spacing: Settings.appearance.sizing.dock.icons.spacing
                property int hoverPadding: Settings.appearance.sizing.dock.icons.hoverPadding
                property int hoverRadius: Settings.appearance.sizing.dock.icons.hoverRadius
            }
        }
        property QtObject topbar: QtObject {
            property int cardRadius: Settings.appearance.sizing.topbar.cardRadius
            property int workspaceButtonFocusedSize: Settings.appearance.sizing.topbar.workspaceButtonFocusedSize
            property int workspaceButtonIdleSize: Settings.appearance.sizing.topbar.workspaceButtonIdleSize
        }
        property QtObject wallpaper: QtObject {
            property int overlayWidth: Settings.appearance.sizing.wallpaper.overlayWidth
            property int overlayHeight: Settings.appearance.sizing.wallpaper.overlayHeight
            property int overlayRadius: Settings.appearance.sizing.wallpaper.overlayRadius
            property int itemWidth: Settings.appearance.sizing.wallpaper.itemWidth
            property int itemHeight: Settings.appearance.sizing.wallpaper.itemHeight
            property int itemRadius: Settings.appearance.sizing.wallpaper.itemRadius
        }
    }
}
