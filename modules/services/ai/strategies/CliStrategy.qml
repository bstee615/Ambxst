import QtQuick

// Base strategy for CLI-backed AI tools.
// Ai.qml routes CLI-model requests here instead of the HTTP/curl path.
//
// Session lifecycle:
//   - First turn (no sessionId): subclass builds a full conversation transcript
//     and starts a new CLI session.
//   - Subsequent turns (sessionId set): subclass uses --resume <sessionId> and
//     sends only the latest user message; context is held by the CLI process.
//   - The sessionId is extracted from the stream and stored per-chat in Ai.qml.
ApiStrategy {
    property bool is_cli: true

    // Returns the argv array for the CLI subprocess.
    // prompt:    full conversation transcript (first turn) OR latest user message (resume)
    // model:     AiModel instance
    // sessionId: active session ID, or "" for the first turn of a chat
    function getCliCommand(prompt, model, sessionId) {
        return [];
    }

    // Parse one stdout line from the subprocess.
    // Returns { content: string, done: bool, sessionId: string|null }
    function parseCliStreamChunk(line) {
        return { content: "", done: false, sessionId: null };
    }
}
