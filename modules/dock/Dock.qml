import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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

            implicitHeight: 55
            implicitWidth: dockBackground.implicitWidth

            margins.bottom: 8
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
                            color: Qt.rgba(0.08, 0.07, 0.07)
                            border.width: 1
                            border.color: "transparent"
                            radius: 13
                        }

                        RowLayout {
                            id: dockRow

                            property real padding: 10

                            anchors {
                                fill: parent
                                leftMargin: padding
                                rightMargin: padding
                                bottomMargin: 2
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