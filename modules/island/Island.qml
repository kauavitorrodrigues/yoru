import "../player"
import "../player/track"
import "../speech/qml"
import "../speech/state"
import "../topbar/widgets"
import "../common"
import qs.services
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

// "Dynamic Island" shown instead of the top bar (layout.topbar.mode = "island").
//
// Collapsed: a small pill glued to the top edge of the screen, horizontally
// centered, showing the current workspace number, the clock and (while
// something plays) a mini waveform. Events (track change, volume, network)
// briefly grow it. Clicking it opens it into a popover with the real
// top bar widgets inside, which stay interactive.
PanelWindow {
    id: root

    readonly property var cfg: Settings.modules.island
    readonly property var sizes: Appearance.sizing.island

    // Event currently surfaced ("" = none)
    property string current: ""
    // Popover open (click / IPC / hover when expandOnHover)
    property bool open: false
    // Ignore the initial values emitted while services are still starting up
    property bool armed: false

    readonly property bool hovered: pillHover.hovered
    readonly property bool recording: SpeechState.state === "recording"
    readonly property bool opened: open || (cfg.expandOnHover && hovered)
    readonly property int workspaceId: Hyprland.focusedWorkspace?.id ?? 1

    readonly property string targetView: {
        if (opened)
            return "popover";
        if (recording)
            return "speech";
        if (current !== "")
            return current;
        return autoHide && !revealed ? "hidden" : "idle";
    }

    // Auto-hide (same idea as the dock): fully hidden until the cursor reaches
    // the top-center of the screen. While hidden, the pill collapses into an
    // invisible hairline strip (hotspotWidth wide) that catches the cursor.
    // It hides again shortly after the cursor leaves, unless something is being shown.
    readonly property bool autoHide: cfg.autoHide
    property bool revealed: !autoHide
    readonly property bool wantsVisible: !autoHide || hovered || opened || recording || current !== ""

    onAutoHideChanged: revealed = !autoHide
    onWantsVisibleChanged: {
        if (wantsVisible) {
            hideTimer.stop();
            revealed = true;
        } else {
            hideTimer.restart();
        }
    }

    // Debounces hiding so a brief mouse-out doesn't flicker the island away.
    Timer {
        id: hideTimer
        interval: Appearance.animation.medium
        onTriggered: root.revealed = false
    }

    // The view actually shown; trails targetView so content can cross-fade
    // while the pill resizes.
    property string view: "idle"

    onTargetViewChanged: swap.restart()

    SequentialAnimation {
        id: swap

        NumberAnimation {
            target: content
            property: "opacity"
            to: 0
            duration: Appearance.animation.instant
            easing.type: Appearance.animationCurves.inOutQuad
        }
        ScriptAction {
            script: root.view = root.targetView
        }
        NumberAnimation {
            target: content
            property: "opacity"
            to: root.targetView === "hidden" ? 0 : 1
            duration: Appearance.animation.fast
            easing.type: Appearance.animationCurves.inOutQuad
        }
    }

    function eventEnabled(name) {
        return (cfg.events ?? []).indexOf(name) !== -1;
    }

    function surface(name) {
        if (!armed || !eventEnabled(name))
            return;
        current = name;
        collapseTimer.restart();
    }

    function viewComponent(name) {
        switch (name) {
        case "popover":
            return popoverView;
        case "speech":
            return speechView;
        case "player":
            return playerView;
        case "volume":
            return volumeView;
        case "network":
            return networkView;
        case "idle":
            return idleView;
        default:
            return null;
        }
    }

    screen: Quickshell.screens.find(s => s.name === cfg.monitor) ?? Quickshell.screens[0]
    color: "transparent"
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:island"

    // Fixed-size window: only the pill is drawn and clickable (see mask), so the
    // surface never has to be resized while the pill animates.
    implicitWidth: 900
    implicitHeight: 440

    anchors {
        top: true
    }

    mask: Region {
        item: pill
    }

    Timer {
        id: armTimer
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: collapseTimer
        interval: root.cfg.autoCollapseMs
        onTriggered: root.current = ""
    }

    Timer {
        id: leaveTimer
        interval: 900
        running: root.open && !root.hovered && root.cfg.closeOnLeave
        onTriggered: root.open = false
    }

    IpcHandler {
        target: "island"

        function toggle(): void {
            root.open = !root.open;
        }
        function expand(): void {
            root.open = true;
        }
        function collapse(): void {
            root.open = false;
        }
    }

    // --- Event sources -----------------------------------------------------

    Connections {
        target: PlayerService

        function onTitleChanged() {
            if (PlayerService.title !== "")
                root.surface("player");
        }
        function onIsPlayingChanged() {
            // Only announce when playback starts; pausing/closing just updates the glance icon.
            if (PlayerService.isPlaying)
                root.surface("player");
        }
    }

    readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property real volume: sinkAudio ? sinkAudio.volume : 0
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false

    PwObjectTracker {
        objects: root.eventEnabled("volume") ? [root.sink] : []
    }

    onVolumeChanged: surface("volume")
    onMutedChanged: surface("volume")

    property bool networkConnected: false

    onNetworkConnectedChanged: surface("network")

    // Always tracked: the collapsed island shows the connection state.
    Process {
        id: routeCheck
        command: ["ip", "route", "show", "default"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.networkConnected = text.trim().length > 0
        }
    }

    Timer {
        id: routeDebounce
        interval: 300
        onTriggered: {
            if (!routeCheck.running)
                routeCheck.running = true;
            else
                routeDebounce.restart();
        }
    }

    Process {
        id: routeMonitor
        command: ["ip", "monitor", "route"]
        running: true
        stdout: SplitParser {
            onRead: routeDebounce.restart()
        }
        onExited: routeRestart.restart()
    }

    Timer {
        id: routeRestart
        interval: 5000
        onTriggered: routeMonitor.running = true
    }

    // --- The pill ----------------------------------------------------------

    // The pill: a single path filled with the exact surface color. Its top
    // edge is flush with the screen and flares outward into concave "wave"
    // curves on both sides; the bottom corners are regular rounded corners.
    Item {
        id: pill

        readonly property bool hidden: root.view === "hidden"
        readonly property bool popover: root.view === "popover"
        readonly property real pad: popover ? root.sizes.openMargin : root.sizes.padding
        readonly property real contentWidth: content.item ? content.item.implicitWidth : 0
        readonly property real contentHeight: content.item ? content.item.implicitHeight : 0
        readonly property real radius: popover ? root.sizes.radius + 6 : root.sizes.radius
        property real flare: hidden ? 0 : root.sizes.flare

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: hidden ? root.sizes.hotspotWidth : Math.min(root.width - flare * 2, Math.max(root.sizes.idleWidth, contentWidth + pad * 2))
        // Single-line views (idle, player, volume, network) all share the idle height.
        readonly property bool singleLine: ["idle", "player", "volume", "network"].indexOf(root.view) !== -1

        height: hidden ? root.sizes.hiddenHeight : (singleLine ? root.sizes.idleHeight : Math.min(root.height, Math.max(root.sizes.idleHeight, contentHeight + (popover ? pad * 2 : 14))))

        Behavior on width {
            NumberAnimation {
                duration: Appearance.animation.medium
                easing.type: Appearance.animationCurves.outCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Appearance.animation.medium
                easing.type: Appearance.animationCurves.outCubic
            }
        }

        Behavior on flare {
            NumberAnimation {
                duration: Appearance.animation.medium
                easing.type: Appearance.animationCurves.outCubic
            }
        }

        Shape {
            id: body

            // Extends past the pill on both sides to hold the flares.
            readonly property real r: Math.min(pill.flare, pill.height / 2)
            readonly property real rb: Math.max(0, Math.min(pill.radius, pill.height - r, pill.width / 2))

            x: -pill.flare
            opacity: pill.hidden ? 0 : 1
            width: pill.width + pill.flare * 2
            height: pill.height
            preferredRendererType: Shape.CurveRenderer

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.fast
                    easing.type: Appearance.animationCurves.inOutQuad
                }
            }

            ShapePath {
                strokeWidth: -1
                fillColor: Appearance.colors.shellSurface

                startX: 0
                startY: 0

                // Left flare, curving in from the top edge down onto the wall
                PathArc {
                    x: body.r
                    y: body.r
                    radiusX: body.r
                    radiusY: body.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: body.r
                    y: body.height - body.rb
                }
                // Bottom-left corner
                PathArc {
                    x: body.r + body.rb
                    y: body.height
                    radiusX: body.rb
                    radiusY: body.rb
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: body.width - body.r - body.rb
                    y: body.height
                }
                // Bottom-right corner
                PathArc {
                    x: body.width - body.r
                    y: body.height - body.rb
                    radiusX: body.rb
                    radiusY: body.rb
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: body.width - body.r
                    y: body.r
                }
                // Right flare
                PathArc {
                    x: body.width
                    y: 0
                    radiusX: body.r
                    radiusY: body.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        HoverHandler {
            id: pillHover
        }

        // Background click: toggles the popover. Widgets inside sit above this
        // and handle their own clicks.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.open = !root.open
        }

        Loader {
            id: content

            anchors.centerIn: parent
            // Keeps the extra height of the collapsed pill below the content (bottom padding).
            anchors.verticalCenterOffset: pill.popover ? 0 : -2
            sourceComponent: root.viewComponent(root.view)
        }
    }

    // --- Views -------------------------------------------------------------

    component IslandText: Text {
        font.family: Appearance.fonts.primary
        font.pixelSize: Appearance.fonts.sizes.base
        color: Appearance.colors.textPrimary
        elide: Text.ElideRight
    }

    // Current workspace number: always visible while collapsed so you never lose track of it.
    component WorkspaceBadge: Rectangle {
        implicitWidth: Math.max(22, label.implicitWidth + 12)
        implicitHeight: 20
        radius: height / 2
        color: Appearance.colors.hoverStrong

        IslandText {
            id: label
            anchors.centerIn: parent
            text: root.workspaceId
            font.bold: true
            font.pixelSize: Appearance.fonts.sizes.sm
        }
    }

    component MiniWave: WaveForm {
        amplitudes: PlayerService.amplitudes
        maxBarHeight: 16
        barWidth: 3
        spacing: 2

        // Tell PlayerService a visible view wants the visualizer (cava runs only then)
        Component.onCompleted: PlayerService.visualizerUsers += 1
        Component.onDestruction: PlayerService.visualizerUsers -= 1
    }

    // Probe for memory usage (polled at layout.topbar.memoryPollMs).
    Memory {
        id: memory
        visible: false
    }

    // Probe for Bluetooth connection state, reusing the top bar widget's logic.
    BluetoothIndicator {
        id: bluetooth
        visible: false
    }

    // Probe for battery state (icon/percent/colors), reusing the top bar widget's logic.
    Battery {
        id: battery
        visible: false
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Component {
        id: idleView

        // Sequential layout (left group, clock, right group): the pill is
        // only as wide as its content, with no padding to balance the sides.
        Item {
            id: idle

            implicitWidth: leftGroup.implicitWidth + 10 + clockText.implicitWidth + 10 + rightGroup.implicitWidth
            implicitHeight: Math.max(clockText.implicitHeight, leftGroup.implicitHeight, rightGroup.implicitHeight)

            IslandText {
                id: clockText
                anchors.verticalCenter: parent.verticalCenter
                x: leftGroup.implicitWidth + 10
                text: Qt.formatDateTime(clock.date, "hh:mm")
                font.bold: true
            }

            Row {
                id: leftGroup
                anchors.right: clockText.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                layoutDirection: Qt.RightToLeft
                spacing: 8

                // Compact Spotify: just the waveform while audio is playing.
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    active: PlayerService.hasAudioContext
                    sourceComponent: MiniWave {}
                }

                // No waveform (Spotify Web in the browser, or paused): Spotify glyph,
                // green while playing, dimmed while paused, gone when the player closes.
                IslandText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: PlayerService.title !== "" && !PlayerService.hasAudioContext
                    text: "󰓇"
                    color: PlayerService.isPlaying ? "#1DB954" : Appearance.colors.textSecondary

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.medium
                            easing.type: Appearance.animationCurves.inOutQuad
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    IslandText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: memory.icon
                        font.pixelSize: Appearance.fonts.sizes.sm
                        color: Appearance.colors.textSecondary
                    }

                    IslandText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: memory.usedGb.toFixed(1)
                        font.pixelSize: Appearance.fonts.sizes.sm
                        font.bold: true
                        color: Appearance.colors.textSecondary
                    }
                }

                WorkspaceBadge {
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Status glance: connection and battery, always visible.
            Row {
                id: rightGroup
                anchors.left: clockText.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                IslandText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.networkConnected ? "󰖩" : "󰖪"
                    color: root.networkConnected ? Appearance.colors.textPrimary : Appearance.colors.stateDanger
                }

                IslandText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: bluetooth.active
                    text: "󰂱"
                    color: Appearance.colors.textPrimary
                }

                BatteryIcon {
                    probe: battery
                    visible: battery.present
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: playerView

        Row {
            spacing: 10

            WorkspaceBadge {
                anchors.verticalCenter: parent.verticalCenter
            }

            IslandText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.sizes.maxWidth - root.sizes.padding * 2 - 110)
                text: PlayerService.artist !== "" ? PlayerService.title + " — " + PlayerService.artist : PlayerService.title
                font.bold: true
            }
        }
    }

    Component {
        id: volumeView

        Row {
            spacing: 10

            WorkspaceBadge {
                anchors.verticalCenter: parent.verticalCenter
            }

            IslandText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted || root.volume === 0 ? "" : root.volume < 0.66 ? "" : ""
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 100
                height: 5
                radius: 2.5
                color: Appearance.colors.indicatorInactive

                Rectangle {
                    width: root.muted ? 0 : parent.width * Math.min(1, root.volume)
                    height: parent.height
                    radius: parent.radius
                    color: Appearance.colors.indicatorActive
                }
            }

            IslandText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
                font.bold: true
            }
        }
    }

    Component {
        id: networkView

        Row {
            spacing: 10

            WorkspaceBadge {
                anchors.verticalCenter: parent.verticalCenter
            }

            IslandText {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰈀"
                color: root.networkConnected ? Appearance.colors.textPrimary : Appearance.colors.stateDanger
            }

            IslandText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.networkConnected ? "Connected" : "Not connected"
                font.bold: true
            }
        }
    }

    Component {
        id: speechView

        Row {
            spacing: 12

            WorkspaceBadge {
                anchors.verticalCenter: parent.verticalCenter
            }

            CenteredBars {
                anchors.verticalCenter: parent.verticalCenter
                amplitudes: SpeechState.micAmplitudes
                barColor: Appearance.colors.textPrimary
                maxBarHeight: 22
                barWidth: 3
                spacing: 3
            }

            IslandText {
                visible: SpeechState.partialTranscript !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 220)
                text: SpeechState.partialTranscript
                color: Appearance.colors.textSecondary
                elide: Text.ElideLeft
            }
        }
    }

    // Opened popover: workspace switcher plus OS-style cards/tiles.
    Component {
        id: popoverView

        IslandPopover {
            networkConnected: root.networkConnected
        }
    }
}
