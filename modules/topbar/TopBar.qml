import "./widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    color: "transparent"
    focusable: false
    aboveWindows: true
    implicitHeight: 40

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
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            spacing: 10

            WorkSpaces {}
        }

        // Center
        Clock { anchors.centerIn: parent }

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
}
