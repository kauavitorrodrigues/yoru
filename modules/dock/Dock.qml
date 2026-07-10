import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import "../player"
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

                        implicitWidth: dockRow.implicitWidth + dockRow.paddingLeft + dockRow.paddingRight
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

                            property real paddingTop: Appearance.sizing.dock.padding.top
                            property real paddingBottom: Appearance.sizing.dock.padding.bottom
                            property real paddingLeft: Appearance.sizing.dock.padding.left
                            property real paddingRight: Appearance.sizing.dock.padding.right

                            readonly property var items: Settings.layout.dock.items

                            anchors {
                                fill: parent
                                leftMargin: paddingLeft
                                rightMargin: paddingRight
                                topMargin: paddingTop
                                bottomMargin: paddingBottom
                            }

                            Component {
                                id: dockAppsComponent
                                DockApps {
                                    buttonPadding: dockRow.paddingLeft
                                }
                            }

                            Component {
                                id: dockPlayerComponent
                                Player {}
                            }

                            Repeater {
                                model: dockRow.items

                                delegate: Loader {
                                    required property string modelData

                                    Layout.fillHeight: modelData !== "player"
                                    Layout.alignment: modelData === "player" ? Qt.AlignVCenter : 0

                                    sourceComponent: {
                                        switch (modelData) {
                                        case "apps":
                                            return dockAppsComponent;
                                        case "player":
                                            return dockPlayerComponent;
                                        default:
                                            return null;
                                        }
                                    }
                                }
                            }

                        }

                    }

                }

            }

        }

    }

}
