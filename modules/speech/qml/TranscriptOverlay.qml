import QtQuick
import Quickshell
import "../../common"
import "../state"

PopupWindow {
    id: root

    property var anchorWindow: null
    property real topGap: 10
    property real maxWidth: 320
    property real panelWidth: maxWidth
    property real hPadding: 20
    property real vPadding: 14
    property int maxVisibleLines: 3

    property real displayOpacity: 0
    property string displayedText: ""
    property string pendingText: ""
    readonly property bool hasText: pendingText.length > 0
    // The daemon's first transcription_partial can take a moment to land
    // (LiveTranscriber needs enough buffered audio for its first tick).
    // An interim loading placeholder was tried here and then dropped: the
    // TopBar's waveform already tells the user recording is live, so the
    // card simply doesn't exist until there's real text — one fade-in
    // with content already in place, instead of a placeholder-to-text
    // transition that kept needing its own tuning.
    property bool active: SpeechState.state === "recording" && hasText
    // The highest line count reached so far this session, capped at
    // maxVisibleLines. Sizing off this instead of the instantaneous
    // lineCount keeps the card pinned at its max height once 3 lines are
    // reached — otherwise the brief moment where a rolled-back/regrown
    // line dips back to 2 lines shrinks the card, then it grows again a
    // tick later, which reads as constant resizing.
    property int peakLineCount: 0

    color: "transparent"
    grabFocus: false
    visible: displayOpacity > 0.001 && anchorWindow !== null

    implicitWidth: panelWidth
    implicitHeight: background.implicitHeight

    anchor {
        window: root.anchorWindow
        rect.x: (root.anchorWindow ? root.anchorWindow.width / 2 : 0) - root.implicitWidth / 2
        rect.y: (root.anchorWindow ? root.anchorWindow.height : 0) + root.topGap
    }

    Behavior on displayOpacity {
        NumberAnimation {
            duration: Appearance.animation.medium
            easing.type: Appearance.animationCurves.inOutQuad
        }
    }

    onActiveChanged: root.displayOpacity = active ? 1 : 0

    // SpeechState.partialTranscript is committed_text + tail_text joined
    // (see SpeechController): the committed part only ever grows, while
    // the trailing tail_text is replaced wholesale on every tick as the
    // daemon's LocalAgreement policy decides more of it is settled. So
    // consecutive updates are "mostly an append" but not a strict one —
    // rolling displayedText back to the last common word boundary, rather
    // than requiring a full prefix match, means only that still-uncertain
    // tail snaps back before the reveal timer types it back in, instead
    // of the whole line flashing on every tick.
    function commonPrefixLength(a, b) {
        const len = Math.min(a.length, b.length);
        let i = 0;
        while (i < len && a[i] === b[i])
            i++;
        while (i > 0 && a[i - 1] !== " ")
            i--;
        return i;
    }

    Connections {
        target: SpeechState
        function onPartialTranscriptChanged() {
            const next = SpeechState.partialTranscript;
            if (next === "") {
                root.displayedText = "";
                root.pendingText = "";
                root.peakLineCount = 0;
            } else {
                const common = root.commonPrefixLength(root.displayedText, next);
                root.displayedText = root.displayedText.substring(0, common);
                root.pendingText = next;
            }
        }
    }

    // Revealing one word at a time still updated the line often enough to
    // feel jittery/busy. Revealing a small group of words per tick keeps
    // the streaming feel but with fewer, calmer updates.
    property int wordsPerReveal: 4

    Timer {
        id: revealTimer
        interval: 220
        repeat: true
        // Without this, a plain repeat:true Timer waits a full interval
        // before its first tick, so the card's fade-in (triggered the
        // instant pendingText gets real content) would render an empty
        // Text for ~220ms before displayedText caught up.
        triggeredOnStart: true
        running: root.displayedText.length < root.pendingText.length
        onTriggered: {
            let boundary = root.displayedText.length;
            for (let i = 0; i < root.wordsPerReveal; i++) {
                const nextSpace = root.pendingText.indexOf(" ", boundary + 1);
                if (nextSpace === -1) {
                    boundary = root.pendingText.length;
                    break;
                }
                boundary = nextSpace;
            }
            root.displayedText = root.pendingText.substring(0, boundary);
        }
    }

    FontMetrics {
        id: fontMetrics
        font.family: Appearance.fonts.primary
        font.pixelSize: Appearance.fonts.sizes.base
    }

    Item {
        id: background

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: root.displayOpacity
        scale: 0.96 + 0.04 * root.displayOpacity
        implicitWidth: root.panelWidth
        implicitHeight: flick.height + root.vPadding * 2

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.shellSurface
            radius: Appearance.sizing.topbar.cardRadius
        }

        Flickable {
            id: flick

            x: root.hPadding
            y: root.vPadding
            width: root.panelWidth - root.hPadding * 2
            // Sized in whole-line steps off the session's peak line count
            // (not the instantaneous lineCount or the continuously-
            // reflowing contentHeight) so the card only grows, never
            // shrinks mid-session — see peakLineCount above.
            height: Math.min(root.peakLineCount, root.maxVisibleLines) * fontMetrics.height
            contentWidth: width
            contentHeight: transcriptText.contentHeight
            clip: true
            interactive: false

            Behavior on height {
                NumberAnimation {
                    duration: Appearance.animation.normal
                    easing.type: Appearance.animationCurves.outCubic
                }
            }

            Behavior on contentY {
                NumberAnimation {
                    duration: Appearance.animation.normal
                    easing.type: Appearance.animationCurves.outCubic
                }
            }

            onContentHeightChanged: contentY = Math.max(0, contentHeight - height)

            Text {
                id: transcriptText

                width: flick.width
                wrapMode: Text.WordWrap
                text: root.displayedText
                color: Appearance.colors.textPrimary
                font.family: Appearance.fonts.primary
                font.pixelSize: Appearance.fonts.sizes.base
                onLineCountChanged: root.peakLineCount = Math.max(root.peakLineCount, lineCount)
            }
        }
    }
}
