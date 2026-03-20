import ".."
import QtQuick
import Quickshell.Io

TopBarWidget {
    id: root

    icon: "\uf4bc"
    label: usedGb.toFixed(1) + " GB"

    property real usedGb: 0

    Process {
        id: memProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.1f\", (t-a)/1048576}' /proc/meminfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.usedGb = parseFloat(text.trim()) || 0
        }
        onExited: timer.restart()
    }

    Timer {
        id: timer
        interval: 5000
        repeat: false
        onTriggered: memProc.running = true
    }
}
