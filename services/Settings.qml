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
    property alias topbar: settingsJsonAdapter.topbar
    property alias speech: settingsJsonAdapter.speech
    property alias player: settingsJsonAdapter.player
    property alias wallpaper: settingsJsonAdapter.wallpaper

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

            property JsonObject topbar: JsonObject {
                property JsonObject workspaces: JsonObject {
                    property int defaultCount: 5
                    property int maxCount: 10
                }
            }

            property JsonObject speech: JsonObject {
                property bool enabled: false
                property string socketPath: ""
            }

            property JsonObject player: JsonObject {
                property string widgetVariant: "full"
            }

            property JsonObject wallpaper: JsonObject {
                property bool enabled: false
                property string directory: ""
                property string cacheDir: ""
            }
        }
    }
}