import "../common"
import QtQuick

// Phone-style battery: a bar that fills with the charge, the percentage
// inside it, and a small bolt next to it while charging.
Row {
    id: batt

    // The Battery widget used as a state probe
    required property var probe

    readonly property real level: Math.max(0, Math.min(1, probe.percent / 100))
    readonly property color fillColor: probe.low ? Appearance.colors.stateDanger : Appearance.colors.indicatorActive

    spacing: 8

    Item {
        id: body

        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 15

        Rectangle {
            id: shell
            anchors.fill: parent
            radius: 5
            color: "transparent"
            border.width: 1
            border.color: Appearance.colors.indicatorInactive
        }

        // Positive terminal
        Rectangle {
            anchors.left: shell.right
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 6
            radius: 1
            color: Appearance.colors.indicatorInactive
        }

        // Charge fill
        Rectangle {
            id: fill
            x: 2
            y: 2
            width: Math.max(0, (body.width - 4) * batt.level)
            height: body.height - 4
            radius: 3
            color: batt.fillColor

            Behavior on width {
                NumberAnimation {
                    duration: Appearance.animation.medium
                    easing.type: Appearance.animationCurves.outCubic
                }
            }
        }

        // Percentage: light text over the empty part, dark text over the fill.
        Text {
            font.family: Appearance.fonts.primary
            color: Appearance.colors.textPrimary
            anchors.centerIn: parent
            text: probe.percent
            font.bold: true
            font.pixelSize: 9
        }

        Item {
            x: fill.x
            y: fill.y
            width: fill.width
            height: fill.height
            clip: true

            Text {
                font.family: Appearance.fonts.primary
                x: body.width / 2 - implicitWidth / 2 - parent.x
                y: body.height / 2 - implicitHeight / 2 - parent.y
                text: probe.percent
                font.bold: true
                font.pixelSize: 9
                color: Appearance.colors.textOnLight
            }
        }
    }

    Text {
        font.family: Appearance.fonts.primary
        color: Appearance.colors.textPrimary
        visible: probe.charging || probe.pluggedIn
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf0e7"
        font.pixelSize: 10
    }
}
