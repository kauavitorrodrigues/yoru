import QtQuick
import QtQuick.Layouts
import "../common"

Item {
    id: root

    property string icon: ""
    property color iconColor: Appearance.colors.textPrimary
    property string label: ""
    property color labelColor: Appearance.colors.textSecondary
    property real hPadding: 20

    implicitWidth: row.implicitWidth + hPadding * 2
    implicitHeight: row.implicitHeight + 15

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.shellSurface
        radius: Appearance.sizing.topbar.cardRadius
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Appearance.fonts.primary
            font.pixelSize: Appearance.fonts.sizes.base
            color: root.iconColor
        }

        Text {
            visible: root.label !== ""
            text: root.label
            font.family: Appearance.fonts.primary
            font.pixelSize: Appearance.fonts.sizes.base
            font.bold: true
            color: root.labelColor
        }
    }
}
