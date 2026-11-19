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
    property alias appearance: settingsJsonAdapter.appearance

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
                    property bool autoHide: false
                    property string preview: "live" // "live" | "static" | "off"
                    property int previewMaxWindows: 3
                }
                property JsonObject topbar: JsonObject {
                    property list<string> left: ["workspaces"]
                    property list<string> center: ["clock"]
                    property list<string> right: ["player", "memory", "network", "bluetooth", "volume"]
                    property int memoryPollMs: 5000
                    property string mode: "bar" // "bar" | "island"
                }
            }

            property JsonObject modules: JsonObject {
                property JsonObject player: JsonObject {
                    property string variant: "full"
                    property bool visualizer: true
                }
                property JsonObject speech: JsonObject {
                    property bool enabled: false
                    property string socketPath: ""
                }
                property JsonObject wallpaper: JsonObject {
                    property bool enabled: false
                    property string directory: ""
                    property string cacheDir: ""
                    // false = square cards, which avoids the offscreen layers + mask
                    // used for rounded corners (cheaper on low-memory machines).
                    property bool roundedCards: true
                }
                property JsonObject island: JsonObject {
                    property int autoCollapseMs: 2500
                    property bool expandOnHover: false // hover also opens it (click always does)
                    property bool closeOnLeave: false // close shortly after the cursor leaves
                    property bool autoHide: false // hide until the cursor reaches the top-center of the screen
                    property string monitor: "" // "" = first screen
                    property list<string> events: ["player", "volume", "network"]
                }
                property JsonObject workspaces: JsonObject {
                    property int defaultCount: 5
                    property int maxCount: 10
                }
            }

            property JsonObject appearance: JsonObject {
                property JsonObject animation: JsonObject {
                    property int instant: 80
                    property int fast: 120
                    property int normal: 200
                    property int medium: 300
                    property int slow: 800
                    property int playerProgress: 900
                    property int marqueePause: 1500
                }
                property JsonObject animationCurves: JsonObject {
                    property int linear: Easing.Linear
                    property int inOutQuad: Easing.InOutQuad
                    property int inCubic: Easing.InCubic
                    property int outCubic: Easing.OutCubic
                }
                property JsonObject fonts: JsonObject {
                    property string primary: "JetBrainsMono Nerd Font"
                    property JsonObject sizes: JsonObject {
                        property int xs: 8
                        property int sm: 12
                        property int md: 13
                        property int base: 14
                    }
                }
                property JsonObject colors: JsonObject {
                    property string transparent: "transparent"

                    property string shellSurface: "#9e141212"
                    property string shellSurfaceElevated: "#b8141212"

                    property string textPrimary: "#ffffff"
                    property string textSecondary: "#c4c4c4"
                    property string textMuted: "#a0a0a0"
                    property string textDisabled: "#4cffffff"
                    property string textOnLight: "#505050"

                    property string stateDanger: "#FF8080"

                    property string hoverSoft: "#1fffffff"
                    property string hoverStrong: "#29ffffff"

                    property string indicatorActive: "#e6ffffff"
                    property string indicatorInactive: "#73ffffff"

                    property string cardPlaceholder: "#14ffffff"
                    property string scrim: "#66000000"
                }
                property JsonObject sizing: JsonObject {
                    property JsonObject dock: JsonObject {
                        property int panelHeight: 84
                        property int bottomMargin: 14
                        property int radius: 18
                        property JsonObject padding: JsonObject {
                            property int top: 1
                            property int bottom: 4
                            property int left: 14
                            property int right: 14
                        }
                        property int previewRadius: 14
                        property JsonObject icons: JsonObject {
                            property int size: 46
                            property int spacing: 12
                            property int hoverPadding: 5
                            property int hoverRadius: 13
                        }
                    }
                    property JsonObject topbar: JsonObject {
                        property int cardRadius: 15
                        property int workspaceButtonFocusedSize: 13
                        property int workspaceButtonIdleSize: 8
                    }
                    property JsonObject island: JsonObject {
                        property int idleHeight: 34
                        property int idleWidth: 120
                        property int hiddenHeight: 4
                        property int hotspotWidth: 360
                        property int radius: 20
                        property int padding: 18
                        property int maxWidth: 440
                        property int openMargin: 10
                        property int flare: 12 // concave "wave" where the island meets the top edge
                    }
                    property JsonObject wallpaper: JsonObject {
                        property int overlayWidth: 1000
                        property int overlayHeight: 550
                        property int overlayRadius: 15
                        property int itemWidth: 200
                        property int itemHeight: 500
                        property int itemRadius: 12
                    }
                }
            }
        }
    }
}