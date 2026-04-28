import QtQuick
import "../../common"

Item {
    id: root

    property string text: ""
    property real maxWidth: 150
    property color color: Appearance.colors.textPrimary
    property int fontSize: Appearance.fonts.sizes.md
    property bool fontBold: false
    readonly property bool _shouldScroll: metrics.width > maxWidth

    implicitWidth: Math.min(metrics.width, maxWidth)
    implicitHeight: label.implicitHeight
    clip: true
    Component.onCompleted: {
        if (_shouldScroll)
            startDelay.restart();

    }
    onTextChanged: {
        scrollAnim.stop();
        label.x = 0;
        if (_shouldScroll)
            startDelay.restart();

    }
    onMaxWidthChanged: {
        scrollAnim.stop();
        label.x = 0;
        if (_shouldScroll)
            startDelay.restart();

    }

    TextMetrics {
        id: metrics

        font: label.font
        text: root.text
    }

    Text {
        id: label

        text: root.text
        color: root.color
        font.family: Appearance.fonts.primary
        font.pixelSize: root.fontSize
        font.bold: root.fontBold
        x: 0
    }

    HoverHandler {
        id: hover

        onHoveredChanged: {
            if (hovered) {
                startDelay.stop();
                if (scrollAnim.running)
                    scrollAnim.pause();

            } else {
                if (scrollAnim.paused)
                    scrollAnim.resume();
                else if (root._shouldScroll)
                    startDelay.restart();
            }
        }
    }

    Timer {
        id: startDelay

        interval: Appearance.animation.marqueePause
        repeat: false
        onTriggered: scrollAnim.start()
    }

    SequentialAnimation {
        id: scrollAnim

        onStopped: {
            if (root._shouldScroll && !hover.hovered)
                startDelay.restart();

        }

        NumberAnimation {
            target: label
            property: "x"
            to: -(metrics.width - root.maxWidth + 10)
            duration: Math.max(25000, (metrics.width - root.maxWidth) * 40)
            easing.type: Appearance.animationCurves.linear
        }

        PauseAnimation {
            duration: Appearance.animation.marqueePause
        }

        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: Appearance.animation.slow
            easing.type: Appearance.animationCurves.inOutQuad
        }

        PauseAnimation {
            duration: Appearance.animation.slow
        }

    }

}
