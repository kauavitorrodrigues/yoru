import "../topbar/widgets"
import "../common"
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Content of the opened island: the usual workspace switcher on top, then a
// grid of quick-setting tiles, 3 per row (volume, network, bluetooth, memory, battery, spotify).
Column {
    id: root

    property bool networkConnected: false

    spacing: 10
    width: Math.max(540, header.implicitWidth)

    // --- Probes (only alive while the popover is open) ---------------------

    Battery {
        id: batteryProbe
        visible: false
    }

    BluetoothIndicator {
        id: bluetoothProbe
        visible: false
    }

    Memory {
        id: memoryProbe
        visible: false
    }

    readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property real volume: sinkAudio ? sinkAudio.volume : 0
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false

    PwObjectTracker {
        objects: [root.sink]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function formatDuration(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    // --- Building blocks ---------------------------------------------------

    component Card: Rectangle {
        color: Appearance.colors.shellSurface
        radius: Appearance.sizing.topbar.cardRadius
    }

    component Label: Text {
        font.family: Appearance.fonts.primary
        font.pixelSize: Appearance.fonts.sizes.base
        color: Appearance.colors.textPrimary
        elide: Text.ElideRight
    }

    component Tile: Card {
        id: tile

        property string icon: ""
        property color iconColor: Appearance.colors.textPrimary
        property string title: ""
        property string subtitle: ""
        property real progress: -1
        property color progressColor: Appearance.colors.indicatorActive
        property bool seekable: false
        // Optional item shown in the top-right corner of the tile.
        property Component accessory: null

        signal clicked
        signal scrolled(real dy)
        signal seek(real value)

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 104

        MouseArea {
            anchors.fill: parent
            onClicked: tile.clicked()
            onWheel: wheel => tile.scrolled(wheel.angleDelta.y)
        }

        Loader {
            sourceComponent: tile.accessory
            active: tile.accessory !== null
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 14
                rightMargin: 12
            }
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 2

            Label {
                text: tile.icon
                color: tile.iconColor
                font.pixelSize: 24
            }

            Label {
                width: parent.width
                text: tile.title
                font.bold: true
            }

            Label {
                width: parent.width
                text: tile.subtitle
                color: Appearance.colors.textMuted
                font.pixelSize: Appearance.fonts.sizes.sm
            }
        }

        Rectangle {
            id: track

            visible: tile.progress >= 0
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 12
            }
            height: 5
            radius: 2.5
            color: Appearance.colors.hoverStrong

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, tile.progress))
                height: parent.height
                radius: parent.radius
                color: tile.progressColor

                Behavior on width {
                    NumberAnimation {
                        duration: Appearance.animation.normal
                        easing.type: Appearance.animationCurves.outCubic
                    }
                }
            }

            MouseArea {
                visible: tile.seekable
                anchors {
                    fill: parent
                    topMargin: -8
                    bottomMargin: -8
                }
                onPressed: mouse => tile.seek(mouse.x / width)
                onPositionChanged: mouse => tile.seek(mouse.x / width)
            }
        }
    }

    // --- Header: workspace switcher (unchanged) + clock --------------------

    RowLayout {
        id: header

        width: root.width
        spacing: 10

        WorkSpaces {}

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: dateRow.implicitWidth + 28

            Row {
                id: dateRow
                anchors.centerIn: parent
                spacing: 8

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    font.bold: true
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "ddd, d MMM")
                    color: Appearance.colors.textSecondary
                    font.pixelSize: Appearance.fonts.sizes.sm
                }
            }
        }
    }

    // --- Quick tiles -------------------------------------------------------

    GridLayout {
        width: root.width
        columns: 3
        rowSpacing: 10
        columnSpacing: 10

        Tile {
            icon: root.muted || root.volume === 0 ? "" : root.volume < 0.66 ? "" : ""
            title: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
            subtitle: root.sink ? (root.sink.nickname || root.sink.description || "Output") : "No output"
            progress: root.muted ? 0 : root.volume
            seekable: true
            onClicked: if (root.sinkAudio)
                root.sinkAudio.muted = !root.sinkAudio.muted
            onSeek: value => {
                if (root.sinkAudio)
                    root.sinkAudio.volume = Math.max(0, Math.min(1, value));
            }
            onScrolled: dy => {
                if (root.sinkAudio)
                    root.sinkAudio.volume = Math.max(0, Math.min(1, root.volume + (dy > 0 ? 0.05 : -0.05)));
            }
        }

        Tile {
            icon: root.networkConnected ? "󰖩" : "󰖪"
            iconColor: root.networkConnected ? Appearance.colors.textPrimary : Appearance.colors.stateDanger
            title: root.networkConnected ? "Connected" : "Offline"
            subtitle: "Network"
        }

        Tile {
            visible: bluetoothProbe.active
            icon: "󰂱"
            title: bluetoothProbe.active ? bluetoothProbe.connectedDevices[0].name : ""
            subtitle: {
                const n = bluetoothProbe.connectedDevices.length;
                return n > 1 ? "Bluetooth · +" + (n - 1) : "Bluetooth";
            }
            accessory: Component {
                BatteryIcon {
                    probe: QtObject {
                        readonly property var dev: bluetoothProbe.active ? bluetoothProbe.connectedDevices[0] : null
                        readonly property bool has: dev !== null && dev.batteryAvailable
                        readonly property int percent: has ? Math.round(dev.battery * 100) : 0
                        readonly property bool charging: false
                        readonly property bool pluggedIn: false
                        readonly property bool low: has && percent <= 15
                    }
                    visible: probe.has
                }
            }
            progress: bluetoothProbe.active && bluetoothProbe.connectedDevices[0].batteryAvailable ? bluetoothProbe.connectedDevices[0].battery : -1
        }

        Tile {
            icon: ""
            title: memoryProbe.usedGb.toFixed(1) + " GB"
            subtitle: memoryProbe.totalGb > 0 ? "of " + memoryProbe.totalGb.toFixed(1) + " GB" : "Memory"
            progress: memoryProbe.totalGb > 0 ? memoryProbe.usedGb / memoryProbe.totalGb : -1
        }

        Tile {
            visible: batteryProbe.present
            icon: batteryProbe.icon
            iconColor: batteryProbe.iconColor
            title: batteryProbe.percent + "%"
            subtitle: {
                const dev = batteryProbe.device;
                if (batteryProbe.charging) {
                    const t = root.formatDuration(dev.timeToFull);
                    return t ? "Charging · " + t : "Charging";
                }
                if (batteryProbe.pluggedIn)
                    return batteryProbe.percent >= 100 ? "Fully charged" : "Plugged in";
                const t = root.formatDuration(dev.timeToEmpty);
                return t ? t + " left" : "On battery";
            }
            progress: batteryProbe.percent / 100
            progressColor: batteryProbe.low ? Appearance.colors.stateDanger : Appearance.colors.indicatorActive
        }

        // Sixth tile: the current Spotify track (click = play/pause, scroll = next/previous).
        Tile {
            id: mediaTile

            readonly property var player: PlayerService.activePlayer
            readonly property real pos: player ? player.position : 0
            readonly property real len: player ? player.length : 0

            visible: player !== null
            icon: "󰓇"
            iconColor: PlayerService.isPlaying ? "#1DB954" : Appearance.colors.textSecondary
            title: PlayerService.title !== "" ? PlayerService.title : "Spotify"
            subtitle: PlayerService.artist
            progress: len > 0 ? pos / len : -1
            progressColor: "#1DB954"

            Behavior on iconColor {
                ColorAnimation {
                    duration: Appearance.animation.medium
                    easing.type: Appearance.animationCurves.inOutQuad
                }
            }

            onClicked: PlayerService.playPause()
            onScrolled: dy => dy > 0 ? PlayerService.previous() : PlayerService.next()

            // Mini transport controls, top right (sit above the tile's own click area).
            Row {
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 10
                    rightMargin: 8
                }
                spacing: 2

                Repeater {
                    model: [
                        { glyph: "󰒮", action: "prev" },
                        { glyph: PlayerService.isPlaying ? "󰏤" : "󰐊", action: "toggle" },
                        { glyph: "󰒭", action: "next" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: 26
                        height: 26
                        radius: 13
                        color: btnArea.containsMouse ? Appearance.colors.hoverStrong : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.glyph
                            font.family: Appearance.fonts.primary
                            font.pixelSize: 16
                            color: Appearance.colors.textPrimary
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                const a = parent.modelData.action;
                                if (a === "prev")
                                    PlayerService.previous();
                                else if (a === "next")
                                    PlayerService.next();
                                else
                                    PlayerService.playPause();
                            }
                        }
                    }
                }
            }

            Timer {
                interval: 1000
                repeat: true
                running: mediaTile.visible && PlayerService.isPlaying
                onTriggered: if (mediaTile.player)
                    mediaTile.player.positionChanged()
            }
        }
    }
}
