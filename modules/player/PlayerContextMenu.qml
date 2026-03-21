import QtQuick
import Quickshell
import qs.services
import "track"

PopupWindow {
    id: root

    required property Item item
    required property bool isOpen

    color: "transparent"
    implicitHeight: 200
    implicitWidth: Math.max(parent.implicitWidth, 250)
    visible: isOpen || panel.opacity > 0
    
    onVisibleChanged: {
        if (visible) {
            panelSlide.y = -8;
            panel.opacity = 0;
            openAnim.start();
        }
    }
    onIsOpenChanged: {
        if (!isOpen)
            closeAnim.start();

    }

    anchor {
        item: item

        rect {
            x: 0
            y: item.height + 8
            width: item.width
            height: 1
        }

    }

    Rectangle {
        id: panel

        anchors.fill: parent
        color: Qt.rgba(0.08, 0.07, 0.07)
        radius: 15
        opacity: 0

        ParallelAnimation {
            id: openAnim

            NumberAnimation {
                target: panel
                property: "opacity"
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: panelSlide
                property: "y"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }

        }

        ParallelAnimation {
            id: closeAnim

            NumberAnimation {
                target: panel
                property: "opacity"
                to: 0
                duration: 150
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: panelSlide
                property: "y"
                to: -8
                duration: 150
                easing.type: Easing.InCubic
            }

        }

        Column {
            id: content

            spacing: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                TrackAlbum { size: 60 }
                TrackInfo { anchors.verticalCenter: parent.verticalCenter}

            }

            TrackProgress {}
            TrackControls {}

        }

        transform: Translate {
            id: panelSlide

            y: -8
        }

    }

}