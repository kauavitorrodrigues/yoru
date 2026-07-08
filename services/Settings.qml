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

    property alias layout: settingsJsonAdapter.layout
    property alias modules: settingsJsonAdapter.modules

    function setDockPinnedApps(appIds) {
        settingsJsonAdapter.layout.dock.pinnedApps = appIds;
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

            property JsonObject layout: JsonObject {
                property JsonObject dock: JsonObject {
                    property string position: "bottom"
                    property list<string> items: ["apps"]
                    property list<string> pinnedApps: []
                }
                property JsonObject topbar: JsonObject {
                    property list<string> left: ["workspaces"]
                    property list<string> center: ["clock"]
                    property list<string> right: ["player", "memory", "network", "volume"]
                }
            }

            property JsonObject modules: JsonObject {
                property JsonObject player: JsonObject {
                    property string variant: "full"
                }
                property JsonObject speech: JsonObject {
                    property bool enabled: false
                    property string socketPath: ""
                }
                property JsonObject wallpaper: JsonObject {
                    property bool enabled: false
                    property string directory: ""
                    property string cacheDir: ""
                }
                property JsonObject workspaces: JsonObject {
                    property int defaultCount: 5
                    property int maxCount: 10
                }
            }
        }
    }
}