import QtQuick

// Base strategy for CLI-backed AI tools.
// Instead of HTTP, these providers run a subprocess and communicate via stdout.
// Ai.qml writes the conversation to a JSON file (conversationFile) then calls
// getCliCommand() to get the argv array for the subprocess.
//
// Output protocol (newline-delimited JSON, read by SplitParser):
//   {"t":"d","x":"text chunk"}    -- streamed text delta
//   {"t":"e","x":"error message"} -- error, shown in chat bubble
//   {"t":"z"}                     -- done signal (optional; process exit also suffices)
ApiStrategy {
    property bool is_cli: true

    // Returns the argv array for the CLI subprocess.
    // conversationFile: absolute path to the JSON file written by Ai.qml, containing:
    //   { messages: [{role, content}], systemPrompt: string, model: string }
    // model: the AiModel instance
    function getCliCommand(conversationFile, model) {
        return [];
    }

    // Parse one line of stdout from the subprocess.
    // Returns { content: string, done: bool }
    function parseCliStreamChunk(line) {
        let trimmed = line.trim();
        if (trimmed === "")
            return { content: "", done: false };

        try {
            let json = JSON.parse(trimmed);
            if (json.t === "d" && json.x)
                return { content: json.x, done: false };
            if (json.t === "e" && json.x)
                return { content: "Error: " + json.x, done: true };
            if (json.t === "z")
                return { content: "", done: true };
        } catch (e) {
            // Non-JSON line — pass through as plain text
            return { content: trimmed + "\n", done: false };
        }

        return { content: "", done: false };
    }
}
