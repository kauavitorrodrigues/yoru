import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import qs.services
import "../common"

Button {

    id: root

    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: Appearance.sizing.dock.iconSize
    property real countDotWidth: 10
    property real countDotHeight: 4
    property var desktopEntry: appToplevel ? DesktopEntries.heuristicLookup(appToplevel.appId) : null

    implicitWidth: iconSize
    implicitHeight: iconSize
    padding: 0
    scale: hoverArea.containsMouse ? 1.08 : 1

    transform: Translate {
        id: hoverLift
        y: hoverArea.containsMouse ? -4 : 0

        Behavior on y {
            NumberAnimation {
                duration: Appearance.animation.fast
                easing.type: Appearance.animationCurves.outCubic
            }
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.animation.fast
            easing.type: Appearance.animationCurves.inOutQuad
        }
    }

    Rectangle {
        id: hoverBg
        width: root.iconSize * 1.25
        height: root.iconSize * 1.25
        anchors.centerIn: parent
        color: Appearance.colors.hoverStrong
        radius: 13
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: Appearance.animation.normal; easing.type: Appearance.animationCurves.inOutQuad }
        }
    }
        
    background: Rectangle {
        color: "transparent"
        border.width: 0
    }

    onClicked: {
        if (!appToplevel || appToplevel.toplevels.length === 0) {
            root.desktopEntry?.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.desktopEntry = appToplevel ? DesktopEntries.heuristicLookup(appToplevel.appId) : null;
        }
    }

    Loader {
        
        id: iconImageLoader
        active: true
        anchors.fill: parent

        sourceComponent: IconImage {
            source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel?.appId), "image-missing")
            implicitSize: root.iconSize
        }

    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton | Qt.RightButton

        onPressed: function(event) {
            if (event.button === Qt.MiddleButton) {
                root.desktopEntry?.execute();
                event.accepted = true;
                return;
            }

            if (event.button === Qt.RightButton) {
                TaskbarApps.togglePin(root.appToplevel?.appId);
                event.accepted = true;
                return;
            }
        }
        
        onEntered: {
            hoverBg.opacity = 1
            root.appListRoot.lastHoveredButton = root
            root.appListRoot.buttonHovered = true
        }

        onExited: {
            hoverBg.opacity = 0
            root.appListRoot.buttonHovered = false
        }

    }

    RowLayout {
        spacing: 3
        anchors {
            top: iconImageLoader.bottom
            topMargin: 3
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: Math.min(root.appToplevel?.toplevels?.length || 0, 3)
            delegate: Rectangle {
                radius: 999
                implicitWidth: root.countDotHeight + 1
                implicitHeight: root.countDotHeight
                color: (root.appToplevel?.toplevels?.some(t => t.activated) || false)
                    ? Appearance.colors.indicatorActive : Appearance.colors.indicatorInactive
            }
        }
    }

}
