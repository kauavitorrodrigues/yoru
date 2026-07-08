import QtQuick
import qs.services
import "../../common"

Item {
    id: root

    property real size: 30
    property bool minimal: false

    implicitWidth: size
    implicitHeight: size

    Text {
        anchors.fill: parent
        visible: root.minimal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: ""
        font.family: Appearance.fonts.primary
        font.pixelSize: 16
        color: "#1DB954"
    }

    Rectangle {
        anchors.fill: parent
        radius: 5
        clip: true
        color: "transparent"
        visible: !root.minimal

        Image {
            id: imgA

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            source: PlayerService.artUrl
        }

        Image {
            id: imgB

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            opacity: 0
        }

        Connections {
            function onArtUrlChanged() {
                imgB.source = PlayerService.artUrl;
            }

            target: PlayerService
        }

        Connections {
            function onStatusChanged() {
                if (imgB.status === Image.Ready)
                    fadeAnim.start();

            }

            target: imgB
        }

        SequentialAnimation {
            id: fadeAnim

            NumberAnimation {
                target: imgB
                property: "opacity"
                to: 1
                duration: Appearance.animation.medium
                easing.type: Appearance.animationCurves.inOutQuad
            }

            ScriptAction {
                script: {
                    imgA.source = imgB.source;
                    imgB.opacity = 0;
                }
            }

        }

    }

}
