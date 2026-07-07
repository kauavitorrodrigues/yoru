import QtQuick
import Quickshell.Io

Item {
    id: root

    property string path: ""
    property bool connected: socketLoader.item ? socketLoader.item.connected : false
    property int reconnectIntervalMs: 2000

    signal rawMessage(string data)
    signal event(string type, var payload)

    onRawMessage: data => {
        let message;
        try {
            message = JSON.parse(data);
        } catch (e) {
            console.warn("SpeechIpc: dropping malformed message:", data);
            return;
        }
        if (!message || typeof message.type !== "string") {
            console.warn("SpeechIpc: dropping message without a type:", data);
            return;
        }
        // Pushed events are enveloped as {"type": "event", "event": "<name>", ...},
        // distinct from command-response messages (which echo their own
        // request type in `type` and aren't relevant to Phase 1).
        if (message.type === "event" && typeof message.event === "string")
            root.event(message.event, message);
    }

    function reconnect() {
        // Recreate the Socket component from scratch so a fresh QLocalSocket
        // is used for each attempt — reassigning properties on an existing
        // Socket does not re-trigger connectToServer() after a failure, and
        // toggling `active` back on in the same tick is a no-op, so the
        // reactivation is deferred to the next event loop turn.
        socketLoader.active = false;
        Qt.callLater(() => {
            if (root.path !== "")
                socketLoader.active = true;
        });
    }

    onPathChanged: {
        if (path !== "")
            reconnect();
        else
            socketLoader.active = false;
    }

    Loader {
        id: socketLoader
        active: false

        sourceComponent: Socket {
            path: root.path
            connected: path !== ""

            parser: SplitParser {
                splitMarker: "\n"
                onRead: data => root.rawMessage(data)
            }

            onConnectionStateChanged: {
                // The daemon pushes events only to clients that explicitly
                // opt in — without this, the connection stays silent forever.
                if (connected) {
                    write(JSON.stringify({
                        type: "subscribe_events"
                    }) + "\n");
                    flush();
                }
            }

            onError: error => {
                if (root.path !== "")
                    reconnectTimer.restart();
            }
        }
    }

    Timer {
        id: reconnectTimer
        interval: root.reconnectIntervalMs
        repeat: false
        onTriggered: root.reconnect()
    }
}
