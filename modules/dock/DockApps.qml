import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Wayland
import qs.services
import "../common"

Item {

    id: root

    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show

    Layout.fillHeight: true
    Layout.topMargin: 0
    implicitWidth: list.contentWidth

    ListView {

        id: list
        spacing: Appearance.sizing.dock.listSpacing
        orientation: ListView.Horizontal
        implicitWidth: contentWidth

        anchors {
            fill: parent
            top: parent.top
            bottom: parent.bottom
        }

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

    PopupWindow {

        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool allPreviewsReady: false

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                previewPopup.allPreviewsReady = false;
                Qt.callLater(previewPopup.updatePreviewReadiness);
            }
        }

        function updatePreviewReadiness() {
            for(var i = 0; i < previewRowLayout.children.length; i++) {
                const view = previewRowLayout.children[i];
                if (view.hasContent === false) {
                    allPreviewsReady = false;
                    return;
                }
            }
            allPreviewsReady = true;
        }

        property bool shouldShow: {
            const hoverConditions = (popupMouseArea.containsMouse || root.buttonHovered)
            return hoverConditions && allPreviewsReady;
        }

        property bool show: false

        onShowChanged: {
            if (!show) {
                allPreviewsReady = false;
                Qt.callLater(updatePreviewReadiness);
            }
        }

        onShouldShowChanged: {
            updateTimer.restart();
        }

        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow
            }
        }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        color: "transparent"

        visible: show
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight * 2

        MouseArea {

            id: popupMouseArea

            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight * 2
            hoverEnabled: true

            x: {
                if (!root.lastHoveredButton) return 0;
                const itemCenter = root.QsWindow?.mapFromItem(root.lastHoveredButton, root.lastHoveredButton?.width / 2, 0);
                return itemCenter.x - width / 2
            }

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.animation.fast
                    easing.type: Appearance.animationCurves.outCubic
                }
            }

            Rectangle {

                id: popupBackground

                property real padding: 5
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0

                clip: true
                color: Appearance.colors.shellSurfaceElevated
                radius: Appearance.sizing.dock.previewRadius
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                transform: Translate {
                    id: previewSlide
                    y: previewPopup.show ? 0 : 10

                    Behavior on y {
                        NumberAnimation {
                            duration: Appearance.animation.normal
                            easing.type: Appearance.animationCurves.outCubic
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.normal
                        easing.type: Appearance.animationCurves.outCubic
                    }
                }

                RowLayout {

                    id: previewRowLayout
                    anchors.centerIn: parent

                    Repeater {

                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }

                        Button {

                            id: windowButton
                            required property var modelData
                            property bool hasContent: screencopyView.hasContent
                            property bool entered: false
                            padding: 0
                            opacity: (previewPopup.show && entered) ? 1 : 0
                            scale: windowButton.hovered ? 1.03 : 1

                            Component.onCompleted: entered = true

                            transform: Translate {
                                y: (previewPopup.show && entered) ? 0 : 8

                                Behavior on y {
                                    NumberAnimation {
                                        duration: Appearance.animation.normal
                                        easing.type: Appearance.animationCurves.outCubic
                                    }
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Appearance.animation.normal
                                    easing.type: Appearance.animationCurves.outCubic
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Appearance.animation.fast
                                    easing.type: Appearance.animationCurves.inOutQuad
                                }
                            }

                            onClicked: { windowButton.modelData?.activate(); }

                            contentItem: ColumnLayout {

                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ScreencopyView {

                                    id: screencopyView
                                    captureSource: windowButton.modelData
                                    live: true
                                    paintCursor: true
                                    constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                    onHasContentChanged: {
                                        previewPopup.updatePreviewReadiness();
                                    }

                                    layer.enabled: true

                                }

                            }

                        }

                    }

                }

            }

        }
        
    }

}
