# Local or frontier orchestrator with local workers

OpenCode exposes two selectable primary agents:

- `orchestrate-local` pins the orchestrator itself to the local Qwen model.
- `orchestrate-frontier` uses the model selected through `/models`; select an
  API-backed Anthropic or OpenAI model before using it.

Both can delegate only to `explore`, `implementer`, and `tester`. All three
workers are pinned to `local/qwen3.6-35b-a3b` at
`http://127.0.0.1:8080/v1`.

OpenCode's title, summary, and compaction work is also pinned locally. The
frontier API therefore receives the user conversation, worker instructions, and
compact worker reports, but not the workers' tool loops.

## OpenAI API key

The OpenAI provider reads `OPENAI_API_KEY` from the environment. Export it from
your private shell configuration, not from this Git-tracked repository:

```sh
export OPENAI_API_KEY="your-key"
```

Restart the terminal, then run `opencode models openai` or `/models` and select
the exact OpenAI model you want. The same variable can initialize Codex API-key
authentication with `printenv OPENAI_API_KEY | codex login --with-api-key`.

Anthropic can be connected separately with `/connect` if desired.

## Choose inside OpenCode

Start `opencode /path/to/project` and use the agent-switch key (Tab by default)
to choose `orchestrate-local` or `orchestrate-frontier`. For the frontier option,
run `/models` and select the desired API model.

You can also select either profile at launch:

```sh
opencode /path/to/project --agent orchestrate-local
opencode /path/to/project --agent orchestrate-frontier --model provider/model-id
```

For a non-interactive task:

```sh
opencode run --dir /path/to/project --agent orchestrate-frontier \
  --model provider/model-id "Describe the task here"
```

Because the default model is local, `orchestrate-frontier` also falls back to
Qwen until an API model is selected.
