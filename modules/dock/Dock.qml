import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common"

// Scope
Scope {
    id: root

    Variants {

        // For each monitor
        model: Quickshell.screens

        PanelWindow {

            id: dockRoot
            screen: modelData
            required property var modelData

            color: "transparent"

            implicitHeight: Appearance.sizing.dock.panelHeight
            implicitWidth: dockBackground.implicitWidth

            margins.bottom: Appearance.sizing.dock.bottomMargin
            WlrLayershell.namespace: "quickshell:dock"

            anchors {
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: dockMouseArea
            }

            MouseArea {
                
                id: dockMouseArea
                height: parent.height

                anchors {
                    top: parent.top
                    topMargin: 0
                    horizontalCenter: parent.horizontalCenter
                }

                implicitWidth: dockHoverRegion.implicitWidth * 2
                hoverEnabled: true

                Item {

                    id: dockHoverRegion
                    anchors.fill: parent
                    implicitWidth: dockBackground.implicitWidth

                    // Wrapper for the dock background
                    Item {

                        id: dockBackground

                        implicitWidth: dockRow.implicitWidth + dockRow.padding * 2
                        height: parent.height

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }

                        // The real rectangle that is visible
                        Rectangle {
                            id: dockVisualBackground
                            anchors.fill: parent
                            anchors.topMargin: 0
                            anchors.bottomMargin: 0
                            color: Appearance.colors.shellSurface
                            radius: Appearance.sizing.dock.radius
                        }

                        RowLayout {
                            id: dockRow

                            property real padding: Appearance.sizing.dock.padding

                            anchors {
                                fill: parent
                                leftMargin: padding
                                rightMargin: padding
                                topMargin: 1
                                bottomMargin: 4
                            }

                            DockApps {
                                id: dockApps
                                buttonPadding: dockRow.padding
                            }

                        }

                    }

                }

            }

        }

    }

}