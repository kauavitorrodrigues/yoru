import QtQuick
import "track"
import Quickshell
import qs.services
import qs.modules.common.functions
import "../common"

Loader {
    id: root

    active: PlayerService.activePlayer !== null || exitTimer.running

    Timer {
        id: exitTimer

        interval: 200
    }

    Connections {
        function onActivePlayerChanged() {
            if (!PlayerService.activePlayer)
                exitTimer.start();

        }

        target: PlayerService
    }

    sourceComponent: Item {
        id: player

        property real padding: 15
        property bool isContextMenuOpen: false

        implicitWidth: content.implicitWidth + padding * 2
        implicitHeight: content.implicitHeight + 15
        opacity: 0
        Component.onCompleted: enterAnim.start()

        Connections {
            function onActivePlayerChanged() {
                if (!PlayerService.activePlayer)
                    exitAnim.start();

            }

            target: PlayerService
        }

        ParallelAnimation {
            id: enterAnim

            NumberAnimation {
                target: player
                property: "opacity"
                to: 1
                duration: Appearance.animation.normal
                easing.type: Appearance.animationCurves.outCubic
            }

            NumberAnimation {
                target: playerSlide
                property: "y"
                to: 0
                duration: Appearance.animation.normal
                easing.type: Appearance.animationCurves.outCubic
            }

        }

        ParallelAnimation {
            id: exitAnim

            NumberAnimation {
                target: player
                property: "opacity"
                to: 0
                duration: Appearance.animation.normal
                easing.type: Appearance.animationCurves.inCubic
            }

            NumberAnimation {
                target: playerSlide
                property: "y"
                to: -6
                duration: Appearance.animation.normal
                easing.type: Appearance.animationCurves.inCubic
            }

        }

        Rectangle {
            id: playerBackground

            anchors.fill: parent
            color: Appearance.colors.shellSurface
            radius: Appearance.sizing.topbar.cardRadius
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    player.isContextMenuOpen = !player.isContextMenuOpen;

            }
        }

        Row {
            id: content

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: padding + 15
            spacing: 10

            TrackAlbum {
                anchors.verticalCenter: parent.verticalCenter
            }

            TrackInfo {
                anchors.verticalCenter: parent.verticalCenter
            }

            WaveForm {
                anchors.verticalCenter: parent.verticalCenter
                amplitudes: PlayerService.amplitudes
            }

        }

        PlayerContextMenu {
            item: player
            isOpen: player.isContextMenuOpen
        }

        transform: Translate {
            id: playerSlide

            y: -6
        }

    }

}
