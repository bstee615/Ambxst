import QtQuick

// GitHub Copilot CLI strategy (standalone `copilot` binary).
// Requires: npm install -g @github/copilot  (or brew install copilot-cli)
// Uses GitHub credentials — no API key needed.
// Runs non-interactively via `copilot -p "prompt" --yolo`.
CliStrategy {
    function getCliCommand(prompt, model, sessionId) {
        return ["copilot", "--yolo", "-p", prompt];
    }

    function parseCliStreamChunk(line) {
        // Strip ANSI colour codes
        let clean = line.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").trim();
        if (clean === "")
            return { content: "", done: false, sessionId: null };
        return { content: clean + "\n", done: false, sessionId: null };
    }
}
