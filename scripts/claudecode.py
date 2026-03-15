#!/usr/bin/env python3
"""
Claude Code SDK bridge for the Ambxst AI assistant panel.

Reads the conversation from a JSON file and streams the response using the
claude-agent-sdk Python package (https://github.com/anthropics/claude-agent-sdk-python).

Usage:
    python3 claudecode.py <conversation_json_file>

Input JSON format:
    {
        "messages":    [{"role": "user"|"assistant", "content": "..."}],
        "systemPrompt": "...",
        "model":        "claude-sonnet-4-5"  (optional)
    }

Output (newline-delimited JSON to stdout):
    {"t":"d","x":"text chunk"}   -- text delta
    {"t":"e","x":"error message"} -- error
    {"t":"z"}                     -- done (emitted on clean exit)
"""

import sys
import json
import asyncio


def emit(event_type: str, text: str | None = None) -> None:
    """Write a newline-delimited JSON event to stdout."""
    obj: dict = {"t": event_type}
    if text is not None:
        obj["x"] = text
    print(json.dumps(obj, ensure_ascii=False), flush=True)


try:
    from claude_agent_sdk import (
        query,
        ClaudeAgentOptions,
        AssistantMessage,
        TextBlock,
        ResultMessage,
    )
except ImportError:
    emit("e", "claude-agent-sdk is not installed. Run: pip install claude-agent-sdk")
    sys.exit(1)


def build_prompt(messages: list[dict], system_prompt: str) -> str:
    """Encode the conversation history as a Human/Assistant transcript string."""
    parts: list[str] = []

    if system_prompt:
        parts.append(f"[System]\n{system_prompt.strip()}")

    for msg in messages:
        role = msg.get("role", "")
        content = (msg.get("content") or "").strip()
        if not content:
            continue
        if role == "user":
            parts.append(f"[Human]\n{content}")
        elif role == "assistant":
            parts.append(f"[Assistant]\n{content}")

    return "\n\n".join(parts).strip()


async def main() -> None:
    if len(sys.argv) < 2:
        emit("e", "Usage: claudecode.py <conversation_json_file>")
        sys.exit(1)

    try:
        with open(sys.argv[1]) as f:
            data = json.load(f)
    except Exception as ex:
        emit("e", f"Failed to read conversation file: {ex}")
        sys.exit(1)

    messages: list[dict] = data.get("messages", [])
    system_prompt: str = data.get("systemPrompt", "")
    model_id: str = data.get("model", "")

    prompt = build_prompt(messages, system_prompt)
    if not prompt:
        emit("e", "No conversation content to send.")
        sys.exit(1)

    # Build SDK options — only set fields that were explicitly provided
    opts_kwargs: dict = {}
    if model_id and model_id not in ("default", ""):
        opts_kwargs["model"] = model_id

    options = ClaudeAgentOptions(**opts_kwargs) if opts_kwargs else None

    try:
        async for message in query(prompt=prompt, options=options):
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock) and block.text:
                        emit("d", block.text)
            elif isinstance(message, ResultMessage):
                emit("z")
    except Exception as ex:
        emit("e", str(ex))
        sys.exit(1)


asyncio.run(main())
