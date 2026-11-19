import ".."
import QtQuick
import Quickshell.Io
import "../../common"

TopBarWidget {
    id: root

    icon: "󰈀"
    iconColor: connected ? Appearance.colors.textPrimary : Appearance.colors.stateDanger
    label: connected ? "Connected" : "Not connected"

    property bool connected: false

    // One-shot check of the default route (runs at start and on each route change).
    Process {
        id: checkProc
        command: ["ip", "route", "show", "default"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.connected = text.trim().length > 0
        }
    }

    // Debounce bursts of route events into a single check.
    Timer {
        id: debounce
        interval: 300
        repeat: false
        onTriggered: {
            if (!checkProc.running) checkProc.running = true;
            else debounce.restart();
        }
    }

    // Single long-lived monitor; restarted if it ever exits.
    Process {
        id: monitor
        command: ["ip", "monitor", "route"]
        running: true
        stdout: SplitParser {
            onRead: debounce.restart()
        }
        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 5000
        repeat: false
        onTriggered: monitor.running = true
    }
}
