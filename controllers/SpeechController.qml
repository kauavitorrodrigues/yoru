import QtQuick
import Quickshell
import "../modules/speech/ipc"
import "../modules/speech/state"
import "../services"

QtObject {
    id: root

    readonly property string resolvedSocketPath: {
        if (Settings.modules.speech.socketPath !== "")
            return Settings.modules.speech.socketPath;
        const runtimeDir = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp";
        return runtimeDir + "/yoru-speech.sock";
    }

    property SpeechIpc ipc: SpeechIpc {
        path: root.resolvedSocketPath
    }

    // Whisper occasionally hallucinates a bracketed/parenthesized
    // non-speech annotation instead of real text on quiet audio (e.g.
    // "[BLANK_AUDIO]", "(music playing)") — strip those rather than
    // showing them as if they were dictated words.
    function stripNonSpeechAnnotations(text) {
        return text.replace(/\[[^\]]*\]|\([^)]*\)/g, " ").replace(/\s+/g, " ").trim();
    }

    // Mirrors yoru-speech's session::ServiceState lifecycle (see
    // message_codec.cpp): recording_finished hands off to transcription
    // before the session is done, so the indicator stays in "processing"
    // until transcription_completed — otherwise it would drop back to
    // idle mid-transcription. Events outside this lifecycle (model_loaded,
    // configuration_changed, ...) are intentionally ignored here.
    function handleEvent(type, payload) {
        if (type === "recording_started") {
            SpeechState.state = "recording";
            SpeechState.partialTranscript = "";
        } else if (type === "recording_finished" || type === "transcription_started") {
            SpeechState.state = "processing";
        } else if (type === "transcription_completed" || type === "session_cancelled") {
            SpeechState.state = "idle";
            SpeechState.partialTranscript = "";
        } else if (type === "error_occurred") {
            SpeechState.state = "error";
        } else if (type === "transcription_partial") {
            // session::TranscriptionPartial (see yoru-speech's events.hpp):
            // committed_text is stable and only ever grows — once a span
            // of words appears there it's never revised — while tail_text
            // is the still-uncertain end of the utterance, replaced
            // wholesale every tick. The shell doesn't need to tell the two
            // apart today, so they're joined into one string here, but
            // that distinction is exactly why displayedText in
            // TranscriptOverlay only ever needs to roll back the last few
            // words rather than the whole line.
            const committed = root.stripNonSpeechAnnotations(payload.committed_text ?? "");
            const tail = root.stripNonSpeechAnnotations(payload.tail_text ?? "");
            SpeechState.partialTranscript = committed + (committed !== "" && tail !== "" ? " " : "") + tail;
        }
    }

    Component.onCompleted: ipc.event.connect(root.handleEvent)
}
