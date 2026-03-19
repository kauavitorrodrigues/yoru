import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import qs.services

Button {

    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 35
    property var desktopEntry: appToplevel ? DesktopEntries.heuristicLookup(appToplevel.appId) : null

    implicitWidth: iconSize
    implicitHeight: iconSize
    padding: 0

    Rectangle {
        id: hoverBg
        width: root.iconSize * 1.25
        height: root.iconSize * 1.25
        anchors.centerIn: parent
        color: '#6de5dfed'
        radius: 10
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
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
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton

        onPressed: function(event) {
            root.desktopEntry?.execute();
            event.accepted = true;
        }

        onEntered: hoverBg.opacity = 0.3
        onExited: hoverBg.opacity = 0
    }

}