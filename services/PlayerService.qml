import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
pragma Singleton

Singleton {
    id: root

    property var _playersWatcher: Mpris.players
    property var supportedPlayersIds: ["spotify"]

    property string title: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property bool isPlaying: false
    
    readonly property bool hasAudioContext: {
        if (!isPlaying) return false;

        const amps = amplitudes ?? [];
        for (let i = 0; i < amps.length; i++) {
            if ((amps[i] ?? 0) > 0.01) return true;
        }
        return false;
    }

    readonly property int barCount: 7 // bars shown; cava emits 8 (bars = 8), the last is dropped
    readonly property bool visualizerEnabled: Settings.modules.player.visualizer ?? true
    // Number of visible player widgets that want the waveform (see Player.qml)
    property int visualizerUsers: 0
    readonly property bool visualizerActive: visualizerEnabled && isPlaying && visualizerUsers > 0

    property var amplitudes: new Array(barCount).fill(0)
    property var _scratch: new Array(barCount).fill(0)
    property bool _hasPending: false
    property string _pendingLine: ""

    readonly property var players: Mpris.players.values
    // The native Spotify app wins; otherwise a browser tab on open.spotify.com
    // (metadata only: its audio isn't routed to the visualizer sink).
    function _isSpotifyWeb(p) {
        const url = p.metadata ? (p.metadata["xesam:url"] ?? "") : "";
        return String(url).startsWith("https://open.spotify.com");
    }

    readonly property var activePlayer: {
        return players.find((p) => supportedPlayersIds.includes(p.identity.toLowerCase()))
            ?? players.find((p) => _isSpotifyWeb(p))
            ?? null;
    }

    function update() {
        if (!activePlayer) {
            title = "";
            artist = "";
            album = "";
            artUrl = "";
            isPlaying = false;
            return ;
        }
        const newArt = activePlayer.trackArtUrl ?? "";
        if (artUrl !== newArt) artUrl = newArt;
        title = activePlayer.trackTitle ?? "";
        artist = activePlayer.trackArtist ?? "";
        album = activePlayer.trackAlbum ?? "";
        isPlaying = activePlayer.isPlaying ?? false;
    }

    function playPause() {
        if (!activePlayer) return;
        activePlayer.togglePlaying();
    }

    function next() {
        if (!activePlayer || !activePlayer.canGoNext) return;
        activePlayer.next();
    }

    function previous() {
        if (!activePlayer || !activePlayer.canGoPrevious) return;
        activePlayer.previous();
    }

    on_PlayersWatcherChanged: update()
    Component.onCompleted: update()
    onActivePlayerChanged: {
        if (activePlayer) {
            try { activePlayer.trackChanged.disconnect(update); } catch (e) {}
            try { activePlayer.postTrackChanged.disconnect(update); } catch (e) {}
            activePlayer.trackChanged.connect(update);
            activePlayer.postTrackChanged.connect(update);
            activePlayer.isPlayingChanged.connect(update);
        }
        update();
    }

    Process {
        id: cavaProc

        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/configs/yoru.conf"]
        running: root.visualizerActive
        onExited: function(code, status) {
            if (root.visualizerActive)
                Qt.callLater(() => { cavaProc.running = root.visualizerActive; });
        }

        stdout: SplitParser {
            onRead: function(line) {
                if (!line.trim())
                    return ;

                root._pendingLine = line;
                root._hasPending = true;
            }
        }

    }

    Timer {
        interval: 33 // ~30fps, matches cava framerate
        repeat: true
        running: root.visualizerActive
        onTriggered: {
            if (!root._hasPending)
                return ;

            root._hasPending = false;
            const parts = root._pendingLine.split(";");
            const cur = root.amplitudes;
            let changed = false;
            const next = root._scratch;
            for (let i = 0; i < root.barCount; i++) {
                const val = Math.min(1, (parseInt(parts[i] ?? "0") || 0) / 1000);
                next[i] = val;
                if (val !== cur[i])
                    changed = true;
            }
            if (!changed)
                return ;

            root.amplitudes = next.slice(0, root.barCount); // only allocate when values changed
        }
    }

    onVisualizerActiveChanged: {
        if (!visualizerActive && amplitudes.some((v) => v !== 0))
            amplitudes = new Array(barCount).fill(0);
    }

}
