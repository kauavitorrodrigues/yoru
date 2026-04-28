pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject fonts
    property QtObject sizing

    animation: QtObject {
        property int instant: 80
        property int fast: 120
        property int normal: 200
        property int medium: 300
        property int slow: 800
        property int playerProgress: 900
        property int marqueePause: 1500
    }

    animationCurves: QtObject {
        property int linear: Easing.Linear
        property int inOutQuad: Easing.InOutQuad
        property int inCubic: Easing.InCubic
        property int outCubic: Easing.OutCubic
    }

    fonts: QtObject {
        property string primary: "JetBrainsMono Nerd Font"
        property QtObject sizes: QtObject {
            property int xs: 8
            property int sm: 12
            property int md: 13
            property int base: 14
        }
    }

    colors: QtObject {
        property color transparent: "transparent"

        property color shellSurface: Qt.rgba(0.08, 0.07, 0.07, 0.62)
        property color shellSurfaceElevated: Qt.rgba(0.08, 0.07, 0.07, 0.72)

        property color textPrimary: "#ffffff"
        property color textSecondary: "#c4c4c4"
        property color textMuted: "#a0a0a0"
        property color textDisabled: Qt.rgba(1, 1, 1, 0.3)
        property color textOnLight: "#505050"

        property color stateDanger: "#FF8080"

        property color hoverSoft: Qt.rgba(1, 1, 1, 0.12)
        property color hoverStrong: Qt.rgba(1, 1, 1, 0.16)

        property color indicatorActive: Qt.rgba(1, 1, 1, 0.9)
        property color indicatorInactive: Qt.rgba(1, 1, 1, 0.45)
    }

    sizing: QtObject {
        property QtObject dock: QtObject {
            property int panelHeight: 72
            property int bottomMargin: 14
            property int radius: 18
            property int padding: 14
            property int iconSize: 38
            property int listSpacing: 12
            property int previewRadius: 14
        }
        property QtObject topbar: QtObject {
            property int cardRadius: 15
            property int workspaceButtonFocusedSize: 13
            property int workspaceButtonIdleSize: 8
        }
    }
}
