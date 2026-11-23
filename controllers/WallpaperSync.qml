import Quickshell
import Quickshell.Io
import QtQuick

// Mirrors the current wallpaper onto every connected monitor. awww only paints
// the outputs that exist when `awww img` runs, so a monitor plugged in later
// (or woken up after a reboot) stays black until the image is re-applied.
Scope {
    id: root

    Process {
        id: syncProcess
        // Take the image shown on the first output that has one and push it
        // to all outputs (awww img without -o targets every output).
        command: ["sh", "-c", "img=$(awww query | sed -n 's/.*currently displaying: image: //p' | head -n1); [ -n \"$img\" ] && awww img \"$img\""]
    }

    Timer {
        id: debounce
        interval: 600
        onTriggered: syncProcess.running = true
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (!syncProcess.running)
                debounce.restart();
        }
    }

    Component.onCompleted: debounce.start()
}
