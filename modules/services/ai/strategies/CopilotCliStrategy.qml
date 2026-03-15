import QtQuick

// GitHub Copilot CLI strategy (gh copilot suggest).
// Uses the user's existing `gh auth` credentials — no API key needed.
// Stateless: each prompt is a fresh suggestion with no session.
//
// Stdin is closed (</dev/null) so the interactive selection menu that
// gh copilot shows after the suggestion receives EOF and the process exits,
// leaving the suggestion text in stdout for SplitParser to consume.
CliStrategy {
    function getCliCommand(prompt, model, sessionId) {
        let escaped = prompt.replace(/'/g, "'\\''");
        return ["bash", "-c", "gh copilot suggest -t shell '" + escaped + "' </dev/null 2>&1"];
    }

    function parseCliStreamChunk(line) {
        // Strip ANSI colour codes produced by gh copilot's formatted output
        let clean = line.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").trim();
        // Discard interactive menu lines (start with ? or >) and blank lines
        if (clean === "" || clean.startsWith("?") || clean.startsWith(">"))
            return { content: "", done: false, sessionId: null };
        return { content: clean + "\n", done: false, sessionId: null };
    }
}
