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
        return Settings.layout.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (!appId || appId === "SEPARATOR") return;
        if (root.isPinned(appId)) {
            Settings.setDockPinnedApps(Settings.layout.dock.pinnedApps.filter(id => id !== appId));
        } else {
            Settings.setDockPinnedApps(Settings.layout.dock.pinnedApps.concat([appId]));
        }
    }

    // Entries are cached by normalized appId and updated in place, so the
    // model keeps stable objects instead of recreating them on every change.
    property var _entries: ({})

    property list<var> apps: {

        var map = new Map();

        // Pinned apps first (even when not running)
        const pinnedApps = Settings.layout.dock.pinnedApps || [];
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

        const cache = root._entries;
        var values = [];

        for (const [key, value] of map) {
            let entry = cache[key];
            if (!entry) {
                entry = appEntryComp.createObject(root, {
                    appId: value.appId || key,
                    toplevels: value.toplevels,
                    pinned: value.pinned || false
                });
                cache[key] = entry;
            } else {
                entry.appId = value.appId || key;
                entry.toplevels = value.toplevels;
                entry.pinned = value.pinned || false;
            }
            values.push(entry);
        }

        // Drop entries for apps that are no longer pinned or running
        for (const key of Object.keys(cache)) {
            if (!map.has(key)) {
                cache[key].destroy();
                delete cache[key];
            }
        }

        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        property string appId: ""
        property list<var> toplevels: []
        property bool pinned: false
    }

    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }

}