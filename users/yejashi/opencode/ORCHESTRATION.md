# Local or frontier orchestrator with local workers

OpenCode exposes two selectable primary agents:

- `orchestrate-local` pins the orchestrator itself to the local Qwen model.
- `orchestrate-frontier` defaults to OpenAI GPT-5.6 Terra with medium reasoning.

Both can delegate only to `explore`, `implementer`, `operator`, and `tester`.
All four workers are pinned to `local/qwen3.6-35b-a3b` at
`http://127.0.0.1:8080/v1`.

Workers intentionally expose narrow tool sets: `explore` searches and reads,
`implementer` edits known files, `tester` runs read-only Bash commands, and
`operator` runs exact state-changing Bash commands such as Git commits and
pushes. The backend runs `--parallel 1`, so both orchestrators set
`parallel_tool_calls: false` and dispatch workers one at a time.

`frontier-implementer` shares the implementer contract but runs on the frontier model, for units dominated by writing prose; titles run on a separate 4B server at `http://127.0.0.1:8081/v1` so they stop evicting the 35B's slot.

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
GPT-5.6 Terra with medium reasoning is selected by default. An explicit model
selection can still override it for the current session.

You can also select either profile at launch:

```sh
opencode /path/to/project --agent orchestrate-local
opencode /path/to/project --agent orchestrate-frontier
```

For a non-interactive task:

```sh
opencode run --dir /path/to/project --agent orchestrate-frontier \
  "Describe the task here"
```
