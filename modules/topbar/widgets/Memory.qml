import ".."
import QtQuick
import Quickshell.Io
import qs.services

TopBarWidget {
    id: root

    icon: ""
    label: usedGb.toFixed(1) + " GB"

    property real usedGb: 0
    property real totalGb: 0

    function parseMeminfo(text) {
        const total = /^MemTotal:\s+(\d+)/m.exec(text);
        const avail = /^MemAvailable:\s+(\d+)/m.exec(text);
        if (!total || !avail) return;
        root.totalGb = parseInt(total[1]) / 1048576;
        root.usedGb = (parseInt(total[1]) - parseInt(avail[1])) / 1048576;
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.parseMeminfo(text())
    }

    Timer {
        interval: Math.max(1000, Settings.memoryPollMs)
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: meminfo.reload()
    }
}
