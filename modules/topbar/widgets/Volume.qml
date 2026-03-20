import QtQuick
import ".."
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    implicitWidth: widget.implicitWidth
    implicitHeight: widget.implicitHeight

    property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    property var sinkAudio: sink ? sink.audio : null
    property real volume: sinkAudio ? sinkAudio.volume : 0
    property bool muted: sinkAudio ? sinkAudio.muted : false
    property int volumePct: Math.round(volume * 100)

    property string volIcon: {
        if (muted) return "\uf026"
        if (volumePct < 33) return "\uf026"
        if (volumePct < 66) return "\uf027"
        return "\uf028"
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    TopBarWidget {
        id: widget
        anchors.fill: parent
        icon: root.volIcon
        iconColor: root.muted ? '#ffffff' : '#ffffff'
        label: root.muted ? "" : root.volumePct + "%"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onWheel: function(wheel) {
            if (!root.sinkAudio) return
            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.sinkAudio.volume = Math.max(0, Math.min(1, root.volume + delta))
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                pavuProc.startDetached()
            } else if (mouse.button === Qt.RightButton) {
                pwtopProc.startDetached()
            }
        }
    }

    Process {
        id: pavuProc
        command: ["pavucontrol"]
    }

    Process {
        id: pwtopProc
        command: ["foot", "-a", "pw-top", "pw-top"]
    }
}
