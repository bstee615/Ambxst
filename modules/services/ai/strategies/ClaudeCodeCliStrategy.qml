import QtQuick

// Claude Code CLI strategy.
// Invokes the `claude` binary (Claude Code CLI by Anthropic) with
// --output-format stream-json for real-time streaming output.
// No separate API key is required — the CLI uses credentials stored via
// `claude auth login`.
//
// Multi-turn context is encoded as a formatted conversation transcript so the
// AI panel's history is preserved across messages.
CliStrategy {
    function getCliCommand(messages, model, systemPrompt) {
        // Build a conversation transcript from the message history.
        // System prompt goes first, then alternating Human/Assistant turns.
        let prompt = "";

        if (systemPrompt && systemPrompt.trim() !== "") {
            prompt += "[System]\n" + systemPrompt.trim() + "\n\n";
        }

        for (let i = 0; i < messages.length; i++) {
            let msg = messages[i];
            if (msg.role === "user") {
                prompt += "[Human]\n" + (msg.content || "") + "\n\n";
            } else if (msg.role === "assistant" && msg.content && msg.content.trim() !== "") {
                prompt += "[Assistant]\n" + msg.content.trim() + "\n\n";
            }
        }

        let args = ["claude", "--print", "--output-format", "stream-json"];

        // Pass an explicit model if one is set (not the placeholder "default")
        if (model.model && model.model !== "default") {
            args.push("--model", model.model);
        }

        args.push(prompt.trim());
        return args;
    }

    // Parse Claude Code's stream-json format.
    // Each line is a JSON event: system / assistant / result
    function parseCliStreamChunk(line) {
        let trimmed = line.trim();
        if (trimmed === "")
            return { content: "", done: false };

        try {
            let json = JSON.parse(trimmed);

            // Assistant event — contains the message content
            if (json.type === "assistant" && json.message && json.message.content) {
                let text = "";
                let parts = json.message.content;
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i].type === "text")
                        text += parts[i].text;
                }
                return { content: text, done: false };
            }

            // Result event — signals completion
            if (json.type === "result") {
                return { content: "", done: true };
            }
        } catch (e) {
            // Non-JSON line (e.g. plain text fallback) — pass through as-is
            return { content: trimmed + "\n", done: false };
        }

        return { content: "", done: false };
    }
}
