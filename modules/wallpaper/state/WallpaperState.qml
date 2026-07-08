pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool visible: false

    function toggle() {
        root.visible = !root.visible;
    }
}
