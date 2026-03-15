import QtQuick

// Claude Code strategy using the claude-agent-sdk Python package.
// Invokes scripts/claudecode.py which uses claude_agent_sdk.query() to stream
// responses via the SDK rather than shelling out to the binary directly.
// Authentication uses the user's existing Claude Code credentials
// (configured via `claude auth login` — no separate API key needed).
CliStrategy {
    // Resolved path to the Python bridge script shipped with Ambxst
    readonly property string scriptPath:
        Qt.resolvedUrl("../../../../../scripts/claudecode.py")
            .toString().replace("file://", "")

    function getCliCommand(conversationFile, model) {
        return ["python3", scriptPath, conversationFile];
    }
}
