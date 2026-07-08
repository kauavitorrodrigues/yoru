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
    implicitHeight: Math.max(leftSection.implicitHeight, centerSection.implicitHeight, rightSection.implicitHeight)

    readonly property var leftWidgetOrder: Settings.layout.topbar.left
    readonly property var centerWidgetOrder: Settings.layout.topbar.center
    readonly property var rightWidgetOrder: Settings.layout.topbar.right

    property real speechIndicatorWidth: 220

    function widgetComponent(name) {
        switch (name) {
        case "workspaces":
            return workspacesComponent;
        case "clock":
            return clockComponent;
        case "player":
            return playerComponent;
        case "memory":
            return memoryComponent;
        case "network":
            return networkComponent;
        case "volume":
            return volumeComponent;
        default:
            return null;
        }
    }

    Component {
        id: workspacesComponent
        WorkSpaces {}
    }

    Component {
        id: clockComponent
        Item {
            id: clockSlot
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

            Component.onCompleted: root.speechIndicatorWidth = speechIndicator.implicitWidth
        }
    }

    Component {
        id: playerComponent
        Player {}
    }

    Component {
        id: memoryComponent
        Memory {}
    }

    Component {
        id: networkComponent
        Network {}
    }

    Component {
        id: volumeComponent
        Volume {}
    }

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

            Repeater {
                model: root.leftWidgetOrder

                delegate: Loader {
                    required property string modelData
                    sourceComponent: root.widgetComponent(modelData)
                }
            }
        }

        // Center
        RowLayout {
            id: centerSection

            spacing: 10

            anchors.centerIn: parent

            Repeater {
                model: root.centerWidgetOrder

                delegate: Loader {
                    required property string modelData
                    sourceComponent: root.widgetComponent(modelData)
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

            Repeater {
                model: root.rightWidgetOrder

                delegate: Loader {
                    required property string modelData
                    sourceComponent: root.widgetComponent(modelData)
                }
            }
        }
    }

    LazyLoader {
        active: Settings.modules.speech.enabled
        component: TranscriptOverlay {
            anchorWindow: root
            maxWidth: root.speechIndicatorWidth * 1.75
        }
    }
}
