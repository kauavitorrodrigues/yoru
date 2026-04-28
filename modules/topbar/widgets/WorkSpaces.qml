import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../common"

Item {
    id: root

    implicitWidth: row.implicitWidth + 20
    implicitHeight: row.implicitHeight + 10

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.shellSurface
        radius: Appearance.sizing.topbar.cardRadius
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
                    radius: Appearance.sizing.topbar.cardRadius 
                    color: btn.focused
                        ? Appearance.colors.textPrimary
                        : btn.hovered ? Appearance.colors.hoverSoft : Appearance.colors.transparent
                }

                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: btn.focused ? "\uf303" : "\uf111"
                    font.family: Appearance.fonts.primary
                    font.pixelSize: btn.focused ? Appearance.sizing.topbar.workspaceButtonFocusedSize : Appearance.sizing.topbar.workspaceButtonIdleSize
                    color: btn.focused ? Appearance.colors.textOnLight : Appearance.colors.textMuted
                }

                onClicked: Hyprland.dispatch("workspace " + wsId)
            }
        }
    }
}
