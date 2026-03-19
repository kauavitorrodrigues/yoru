import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {

    id: root

    property Item lastHoveredButton
    property real buttonPadding: 5

    Layout.fillHeight: true
    implicitWidth: list.contentWidth

    ListView {
        id: list
        spacing: 14
        orientation: ListView.Horizontal
        anchors.fill: parent
        implicitWidth: contentWidth

        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps
        }

        delegate: Item {
            required property var modelData
            width: button.implicitWidth
            height: list.height

            DockAppButton {
                id: button
                anchors.centerIn: parent
                appToplevel: modelData
                appListRoot: root
            }
        }

    }

}