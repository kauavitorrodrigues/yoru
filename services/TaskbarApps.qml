pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function normalizedAppId(appId) {
        return (appId || "").toLowerCase();
    }

    function isPinned(appId) {
        return Settings.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (!appId || appId === "SEPARATOR") return;
        if (root.isPinned(appId)) {
            Settings.setDockPinnedApps(Settings.dock.pinnedApps.filter(id => id !== appId));
        } else {
            Settings.setDockPinnedApps(Settings.dock.pinnedApps.concat([appId]));
        }
    }

    property list<var> apps: {

        var map = new Map();

        // Pinned apps first (even when not running)
        const pinnedApps = Settings.dock.pinnedApps || [];
        for (const appId of pinnedApps) {
            const key = normalizedAppId(appId);
            if (!key.length) continue;
            if (!map.has(key)) map.set(key, ({
                appId: appId,
                pinned: true,
                toplevels: []
            }));
        }

        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            const key = normalizedAppId(toplevel.appId);
            if (!map.has(key)) map.set(key, ({
                appId: toplevel.appId,
                pinned: false,
                toplevels: []
            }));
            map.get(key).toplevels.push(toplevel);
        }

        var values = [];

        for (const [key, value] of map) {
            values.push(appEntryComp.createObject(null, {
                appId: value.appId || key,
                toplevels: value.toplevels,
                pinned: value.pinned || false
            }));
        }

        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }

    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }

}