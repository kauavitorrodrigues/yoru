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
        model: Quickshell.screens.filter(s => Settings.screenEnabled(s))

        Scope {

            id: screenScope
            required property var modelData

            readonly property bool autoHide: Settings.layout.dock.autoHide
            property bool revealed: !autoHide

            onAutoHideChanged: revealed = !autoHide

            // Debounces hiding so a brief mouse-out (e.g. crossing icon
            // gaps, or the gap between the hotspot and the dock itself)
            // doesn't flicker the dock away.
            Timer {
                id: hideTimer
                interval: Appearance.animation.medium
                onTriggered: screenScope.revealed = false
            }

            function onHoverChanged(hovering) {
                if (!screenScope.autoHide)
                    return;

                if (hovering) {
                    hideTimer.stop();
                    screenScope.revealed = true;
                } else {
                    hideTimer.restart();
                }
            }

            // A hairline strip glued to the true bottom edge of the screen,
            // spanning its full width. This is the only thing that reveals
            // the dock in auto-hide mode: the dock's own hit area (below)
            // floats above the screen edge by its bottomMargin, which sits
            // right on top of normal app content (e.g. a chat app's send
            // button) and would trigger false reveals if used as the
            // trigger itself. Only loaded while auto-hide is on.
            LazyLoader {
                active: screenScope.autoHide

                component: PanelWindow {
                    id: hotspot
                    screen: screenScope.modelData
                    color: "transparent"

                    implicitHeight: 4
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.namespace: "quickshell:dock-hotspot"

                    anchors {
                        bottom: true
                        left: true
                        right: true
                    }

                    mask: Region {
                        item: hotspotArea
                    }

                    MouseArea {
                        id: hotspotArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: screenScope.onHoverChanged(containsMouse)
                    }
                }
            }

            PanelWindow {

                id: dockRoot
                screen: screenScope.modelData

                color: "transparent"

                implicitHeight: Appearance.sizing.dock.panelHeight
                implicitWidth: dockBackground.implicitWidth

                margins.bottom: Appearance.sizing.dock.bottomMargin
                WlrLayershell.namespace: "quickshell:dock"
                WlrLayershell.layer: screenScope.autoHide ? WlrLayer.Overlay : WlrLayer.Top

                // Auto-hide never reserves compositor space (Ignore): windows
                // can use the full screen, and the dock only floats over them
                // on hover. Otherwise Auto reserves exactly the panel's own
                // height, same as the default (unmodified) behavior.
                exclusionMode: screenScope.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto

                anchors {
                    bottom: true
                    left: true
                    right: true
                }

                // Once revealed, hovering the dock's own hit area keeps it
                // open, and leaving it starts the hide countdown below.
                Connections {
                    target: dockMouseArea
                    function onContainsMouseChanged() {
                        screenScope.onHoverChanged(dockMouseArea.containsMouse);
                    }
                }

                // While hidden in auto-hide mode, dockMouseArea is excluded
                // from the mask entirely (empty region = fully click-through)
                // so its hit area can't intercept input meant for whatever's
                // underneath. Only the hotspot above can bring it back.
                mask: Region {
                    item: (!screenScope.autoHide || screenScope.revealed) ? dockMouseArea : null
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

                            opacity: screenScope.revealed ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Appearance.animation.normal
                                    easing.type: Appearance.animationCurves.outCubic
                                }
                            }

                            transform: Translate {
                                y: screenScope.revealed ? 0 : Appearance.sizing.dock.panelHeight * 0.35

                                Behavior on y {
                                    NumberAnimation {
                                        duration: Appearance.animation.normal
                                        easing.type: Appearance.animationCurves.outCubic
                                    }
                                }
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

}
