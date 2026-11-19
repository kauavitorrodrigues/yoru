pragma Singleton

import Quickshell
import QtQuick
import "../../common"

Singleton {
    id: root

    property bool visible: false

    // True while the overlay needs to exist: from the moment the picker is
    // requested until its fade-out has finished. shell.qml drives the
    // overlay's LazyLoader from this, so the window, model and carousel are
    // released while the picker is closed.
    property bool loaded: false

    function toggle() {
        root.visible = !root.visible;
    }

    onVisibleChanged: {
        if (root.visible) {
            // A close reversed mid fade-out keeps the existing overlay alive.
            unloadTimer.stop();
            root.loaded = true;
        } else {
            unloadTimer.restart();
        }
    }

    Timer {
        id: unloadTimer
        // Longer than the overlay's fade-out + unmap (Appearance.animation.fast + 30)
        // so the overlay is never destroyed while still animating out.
        interval: Appearance.animation.fast + 100
        onTriggered: root.loaded = false
    }
}
