import QtQuick

// Claude Code CLI strategy.
// Invokes the `claude` binary directly with --output-format stream-json.
// Authentication uses credentials stored by `claude auth login`.
//
// Session handling:
//   First turn  → claude --print --output-format stream-json [--model M] <transcript>
//   Later turns → claude --print --output-format stream-json [--model M] --resume <id> <message>
//
// The `result` event in the stream carries the session_id, which Ai.qml
// stores and passes back on every subsequent turn for this chat.
CliStrategy {
    function getCliCommand(prompt, model, sessionId) {
        let args = ["claude", "--print", "--output-format", "stream-json", "--dangerously-skip-permissions"];

        if (sessionId) {
            // Resume the existing session — send only the new user message
            args.push("--resume", sessionId);
        }

        if (model.model && model.model !== "default") {
            args.push("--model", model.model);
        }

        args.push(prompt);
        return args;
    }

    // Parse claude's stream-json format (newline-delimited JSON events).
    function parseCliStreamChunk(line) {
        let trimmed = line.trim();
        if (trimmed === "")
            return { content: "", done: false, sessionId: null };

        try {
            let json = JSON.parse(trimmed);

            // assistant event — streamed text content
            if (json.type === "assistant" && json.message && json.message.content) {
                let text = "";
                let parts = json.message.content;
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i].type === "text")
                        text += parts[i].text;
                }
                return { content: text, done: false, sessionId: null };
            }

            // result event — end of turn; carries the session_id
            if (json.type === "result") {
                return {
                    content: "",
                    done: true,
                    sessionId: json.session_id || null
                };
            }
        } catch (e) {
            // Non-JSON line (e.g. stderr mixed in) — ignore silently
        }

        return { content: "", done: false, sessionId: null };
    }
}
