import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Scope
Scope {
    id: root

    Variants {

        // For each monitor
        model: Quickshell.screens

        PanelWindow {

            required property var modelData

            color: "transparent"
            implicitHeight: 50
            margins.bottom: 8
            WlrLayershell.namespace: "quickshell:dock"

            anchors {
                bottom: true
                left: true
                right: true
            }

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