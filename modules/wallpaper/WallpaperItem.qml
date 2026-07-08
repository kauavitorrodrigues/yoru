import QtQuick
import QtQuick.Effects
import "../common"
import "state"

Item {
    id: root

    required property int index
    required property string thumbnailPath
    required property string animatedThumbnailPath
    required property string fileName
    required property int distanceFromCenter

    signal applyRequested(int itemIndex)

    width: Appearance.sizing.wallpaper.itemWidth
    height: Appearance.sizing.wallpaper.itemHeight

    readonly property bool isAnimated: fileName.toLowerCase().endsWith(".gif")
    // WallpaperState.visible is required here: distanceFromCenter doesn't
    // change when the overlay closes, so without it a centered GIF kept
    // decoding at 75-90% CPU for several seconds after the picker closed.
    readonly property bool showAnimated: isAnimated && distanceFromCenter === 0 && WallpaperState.visible
    // Empty until the cache has produced a downscaled copy of the GIF (see
    // generate_thumbnails.py), and whenever not shown, so the AnimatedImage
    // below only ever decodes that small cached file, never the original.
    readonly property string animatedSource: showAnimated ? animatedThumbnailPath : ""

    z: 10 - distanceFromCenter
    transformOrigin: Item.Bottom

    opacity: distanceFromCenter === 0 ? 1.0 : distanceFromCenter === 1 ? 0.85 : distanceFromCenter === 2 ? 0.65 : 0.45

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.animation.fast
            easing.type: Appearance.animationCurves.outCubic
        }
    }

    // Rendered to an offscreen layer so MultiEffect can mask it below.
    // Hidden via opacity, not `visible: false`: an invisible layer source
    // stops receiving live repaints once something inside it (like the
    // AnimatedImage below) goes through an invisible period and becomes
    // relevant again, leaving the layer stuck on a stale frame. Reproduced
    // with a real wallpaper GIF, whose playback kept advancing internally
    // while the card rendered blank after being scrolled away and back.
    Item {
        id: cardSource
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        opacity: 0

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.cardPlaceholder
        }

        Image {
            id: staticThumb
            anchors.fill: parent
            source: thumbnailPath || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            // Stays up until the GIF has a frame ready, so centering one
            // never flashes a bare placeholder while it decodes.
            visible: !root.showAnimated || animatedThumb.status !== Image.Ready
        }

        AnimatedImage {
            id: animatedThumb
            anchors.fill: parent
            source: root.animatedSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            playing: root.showAnimated
            visible: root.showAnimated && status === Image.Ready
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.scrim
            opacity: distanceFromCenter === 0 ? 0.0 : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.fast
                }
            }
        }
    }

    // roundMask's shape clips cardSource's layer texture to rounded corners.
    Rectangle {
        id: roundMask
        anchors.fill: parent
        radius: Appearance.sizing.wallpaper.itemRadius
        color: "white"
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    MultiEffect {
        anchors.fill: parent
        source: cardSource
        maskEnabled: true
        maskSource: roundMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.0
    }

    // Drawn outside the masked pipeline so the border stays crisp.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: distanceFromCenter === 0 ? Appearance.colors.textPrimary : "transparent"
        border.width: 2
        radius: Appearance.sizing.wallpaper.itemRadius
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ListView.view.currentIndex = root.index
        onDoubleClicked: if (root.distanceFromCenter === 0)
            root.applyRequested(root.index)
    }
}
