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

    Process {
        id: netProc
        command: ["sh", "-c", "ip route show default 2>/dev/null | grep -q default && echo 1 || echo 0"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.connected = text.trim() === "1"
        }
        onExited: netTimer.restart()
    }

    Timer {
        id: netTimer
        interval: 10000
        repeat: false
        onTriggered: netProc.running = true
    }
}