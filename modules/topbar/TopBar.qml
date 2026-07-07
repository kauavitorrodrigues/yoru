import "../player"
import "./widgets"
import "../speech/qml"
import "../speech/state"
import "../common"
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: root

    color: "transparent"
    focusable: false
    aboveWindows: true
    implicitHeight: leftSection.implicitHeight

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 8
        left: 10
        right: 10
    }

    Item {

        id: content
        anchors.fill: parent

        // Left
        RowLayout {
            id: leftSection

            spacing: 10

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            WorkSpaces {}
            Player {}

        }

        // Center
        Item {
            id: centerSection
            anchors.centerIn: parent
            implicitWidth: Math.max(clock.implicitWidth, speechIndicator.implicitWidth)
            implicitHeight: Math.max(clock.implicitHeight, speechIndicator.implicitHeight)

            Clock {
                id: clock
                anchors.centerIn: parent
                opacity: SpeechState.state !== "recording" ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.medium
                        easing.type: Appearance.animationCurves.inOutQuad
                    }
                }
            }

            SpeechIndicator {
                id: speechIndicator
                anchors.centerIn: parent
                opacity: SpeechState.state === "recording" ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.medium
                        easing.type: Appearance.animationCurves.inOutQuad
                    }
                }
            }
        }

        // Right
        RowLayout {
            id: rightSection
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 10

            Memory {}
            Network {}
            Volume {}
        }
    }

    LazyLoader {
        active: Settings.speech.enabled
        component: TranscriptOverlay {
            anchorWindow: root
            maxWidth: speechIndicator.implicitWidth * 1.75
        }
    }
}
