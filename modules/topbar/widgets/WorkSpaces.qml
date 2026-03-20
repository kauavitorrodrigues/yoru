import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    implicitWidth: row.implicitWidth + 20
    implicitHeight: row.implicitHeight + 10

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.08, 0.07, 0.07)
        radius: 15
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: Hyprland.workspaces

            delegate: Button {

                id: btn
                required property int index

                readonly property int wsId: index + 1
                readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId

                implicitWidth: 40
                implicitHeight: 25

                leftPadding: 10
                rightPadding: btn.focused ? 14 : 10

                background: Rectangle {
                    radius: 15 
                    color: btn.focused
                        ? '#ffffff'
                        : btn.hovered ? Qt.rgba(0.13, 0.12, 0.12) : "transparent"
                }

                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: btn.focused ? "\uf303" : "\uf111"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: btn.focused ? 13 : 8
                    color: btn.focused ? "#505050" : "#a0a0a0"
                }

                onClicked: Hyprland.dispatch("workspace " + wsId)
            }
        }
    }
}
