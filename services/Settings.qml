pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string configDir: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    property string filePath: configDir + "/yoru/settings.json"
    property bool ready: false

    property alias dock: settingsJsonAdapter.dock

    function setDockPinnedApps(appIds) {
        settingsJsonAdapter.dock.pinnedApps = appIds;
    }

    Timer {
        id: fileReloadTimer
        interval: 80
        repeat: false
        onTriggered: settingsFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: 80
        repeat: false
        onTriggered: settingsFileView.writeAdapter()
    }

    FileView {
        id: settingsFileView
        path: root.filePath
        watchChanges: true

        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                // Bootstrap settings file with adapter defaults.
                fileWriteTimer.restart();
                root.ready = true;
            }
        }

        adapter: JsonAdapter {
            id: settingsJsonAdapter

            property JsonObject dock: JsonObject {
                property list<string> pinnedApps: []
            }
        }
    }
}