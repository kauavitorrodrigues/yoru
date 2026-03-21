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

    property var amplitudes: new Array(20).fill(0)
    property bool _hasPending: false
    property string _pendingLine: ""

    readonly property var players: Mpris.players.values
    readonly property var activePlayer: {
        return players.find((p) => {
            return supportedPlayersIds.includes(p.identity.toLowerCase());
        }) ?? null;
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

        command: ["bash", "-c", "exec cava -p \"$HOME/.config/cava/configs/yoru.conf\""]
        running: root.isPlaying
        onExited: function(code, status) {
            if (root.isPlaying)
                Qt.callLater(() => {
                return cavaProc.running = true;
            });

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
        interval: 16 // ~60fps
        repeat: true
        running: root.isPlaying
        onTriggered: {
            if (!root._hasPending)
                return ;

            root._hasPending = false;
            const parts = root._pendingLine.split(";");
            const step = 3; // skip every 3 values
            const arr = [];
            for (let i = 0; i < 20; i += step) {
                const val = parseInt(parts[i] ?? "0") || 0;
                arr.push(Math.min(1, val / 1000));
            }
            root.amplitudes = arr;
        }
    }

}