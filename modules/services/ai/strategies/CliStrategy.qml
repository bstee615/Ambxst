import QtQuick

// Base strategy for CLI-based AI tools.
// Subclasses implement getCliCommand() instead of HTTP methods.
// The Ai.qml service detects is_cli and routes requests through a Process
// rather than the curl HTTP path.
ApiStrategy {
    property bool is_cli: true

    // Returns the argv array for the CLI command, incorporating the full
    // conversation history and system prompt so the tool has context.
    // messages: array of { role, content } objects (same format as API messages)
    // model: AiModel instance
    // systemPrompt: string (may be empty)
    function getCliCommand(messages, model, systemPrompt) {
        return [];
    }

    // Parse a single line of CLI stdout for streaming display.
    // Return { content: "token", done: bool }
    // Default: treat each non-empty line as plain text content.
    function parseCliStreamChunk(line) {
        let trimmed = line.trim();
        if (trimmed === "")
            return { content: "", done: false };
        return { content: trimmed + "\n", done: false };
    }
}
