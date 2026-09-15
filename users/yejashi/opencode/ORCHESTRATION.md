# Local or frontier orchestrator with local workers

OpenCode exposes these selectable primary agents:

- `code-local` is flat: one local agent that reads, edits and runs commands
  itself. No delegation.
- `orchestrate-local` pins the orchestrator itself to the local Qwen model.
- `orchestrate-frontier` defaults to OpenAI GPT-5.6 Terra with medium reasoning.

## Which one to start with

`orchestrate-local` is the daily driver. `code-local` exists for the cases where
delegation is pure overhead -- a one-line fix, a quick question, a rename -- and
for when you want an answer in thirty seconds rather than ten minutes.

Delegation is not free. Every worker call is a fresh context plus a round trip,
and at 7-10 s per request on this hardware that overhead is the dominant cost on
a small task. A measured 20-task SWE-bench run of `orchestrate-local` spent 36%
of all model requests inside the orchestrator and only 12% inside the
implementer, and the median run did not touch source until 6.6 minutes in (21.8
minutes for runs that then ran out of clock). For a one-file change that tax buys
nothing.

What orchestration does buy is context isolation, and that is a real benefit for
a 35B model: workers absorb the large file contents and long test logs so the
decision-making context stays small. Published results agree that small
open-weight models degrade sharply as a task spans more files, so keep
`orchestrate-local` for genuinely large, multi-subsystem, multi-stage work.

Rough rule:

| situation | agent |
| --- | --- |
| trivial, self-contained, and you want it now | `code-local` |
| anything with real investigation or several steps | `orchestrate-local` |
| many files across subsystems, or long staged work | `orchestrate-local` |
| hard design judgment, or a task worth API spend | `orchestrate-frontier` |
| chat, prose, no tools | `raw` |

`code-local` is told to say so when a task outgrows it, rather than degrading
quietly. Treat that as the signal to switch.

Like the orchestrators, it batches independent greps and reads into one round
trip.

Both can delegate only to `explore`, `implementer`, `operator`, and `tester`.
All four workers are pinned to `local/qwen3.6-35b-a3b` at
`http://127.0.0.1:8080/v1`.

## Why the orchestrator can read

The orchestrators hold `read`, `glob` and `grep`, and no write or shell tools.

That is a change from the original design, which withheld `read` to protect the
orchestrator's context. Measurement showed the protection was not needed: the
model server runs at `-c 65536` and the median opencode session uses about 11.8k
tokens, roughly 18% of the ceiling. Meanwhile an `explore` round trip costs about
three model requests (271 requests across 87 delegations in a 20-task benchmark)
where reading a known file costs one, and real usage across 451 sessions shows
785 `read` calls against 337 `task` calls -- more than two reads per delegation,
every one of them previously paid for as a round trip.

So the trade was inverted: context was cheap and round trips were expensive, and
the design was optimising the wrong one. `explore` is now for breadth -- sweeping
files you have not identified yet and distilling them -- while a known file is
read directly. Its report ceiling went from fifteen to forty lines for the same
reason: a richer answer that avoids a follow-up question is worth the tokens.

Both orchestrators also set `parallel_tool_calls: true` so independent greps and
reads batch into one turn. The prompt still forbids two `task` calls in a single
turn, because the backend has one slot; that constraint is enforced by
instruction rather than by the flag.

`tool_output` was raised to 2000 lines / 64KB, since truncated test output was
causing repeat runs to recover information that would now simply fit.

## What was tried and rejected

A "converge on a change" section was added to the orchestrate prompt and then
removed. It told the orchestrator to reach a candidate change quickly, treat a
wrong first attempt as cheap, and revise from verification evidence. Measured on
three benchmark instances it made things worse, not better.

The clearest case was `django__django-15061`, run three times: it produced the
byte-identical patch every time while model requests went 39 -> 84 -> 91 and
wall-clock went 7.9 -> 15.9 -> 27.3 minutes. Shell calls went 8 -> 33 -> 55. The
text had licensed an implement-verify-revise loop that churned without changing
the answer.

An earlier version of the same section also carried a numeric budget ("use
roughly three investigative worker calls"). Instances that were already using two
went *up* to seven: stating a number in a prompt anchors behaviour toward it from
below as well as above. If a limit is ever reintroduced here, make it a
prohibition, not an allowance.

What survived from that work is prohibitive rather than permissive: the
reproduction-artifact rules, the narrower verification targets, and the `tester`
ban on writing into the working tree. Those cannot add round trips.

The lesson worth keeping: changes to *mechanism* (what the agent can do, how many
round trips something costs) behaved predictably. Changes to *prose* (asking the
model to behave differently) backfired twice. Prefer the former.

Workers intentionally expose narrow tool sets: `explore` searches and reads,
`implementer` edits known files, `tester` runs read-only Bash commands, and
`operator` runs exact state-changing Bash commands such as Git commits and
pushes. The backend runs `--parallel 1`, so workers are dispatched one at a time;
that is enforced by the orchestrate prompt rather than by a config flag.

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
