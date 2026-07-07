pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string state: "idle"

    property var micAmplitudes: new Array(17).fill(0)
    property bool _hasPendingMicLine: false
    property string _pendingMicLine: ""

    property string partialTranscript: ""

    Process {
        id: micCavaProc

        // The source is resolved at process start (not hardcoded) so this
        // keeps working across machines/mic devices without reconfiguring.
        command: ["bash", "-c", "exec cava -p <(sed \"s/@SOURCE@/$(pactl get-default-source)/\" \"$HOME/.config/cava/configs/mic.conf\")"]
        running: root.state === "recording"

        stdout: SplitParser {
            onRead: function(line) {
                if (!line.trim())
                    return;

                root._pendingMicLine = line;
                root._hasPendingMicLine = true;
            }
        }
    }

    Timer {
        interval: 16 // ~60fps
        repeat: true
        running: root.state === "recording"
        onTriggered: {
            if (!root._hasPendingMicLine)
                return;

            root._hasPendingMicLine = false;
            const parts = root._pendingMicLine.split(";");
            const step = 3; // cava's [smoothing] waves/monstercat already interpolate neighboring bars
            const arr = [];
            for (let i = 0; i < 50; i += step) {
                const val = parseInt(parts[i] ?? "0") || 0;
                arr.push(Math.min(1, val / 1000));
            }
            root.micAmplitudes = arr;
        }
    }

    // Reserved for future phases — not implemented yet:
    // property bool modelDownloading: false
    // property string errorMessage: ""
}
