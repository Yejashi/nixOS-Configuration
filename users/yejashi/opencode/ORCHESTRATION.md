# OpenCode: local lead engineer and specialists

Start a fresh session with `oc`. The default agent is `orchestrate-local`.
For a standalone terminal session, use:

```sh
opencode --agent orchestrate-local
```

## How work flows

The lead owns the user's goal, investigation, integration and verification. It
can read, edit and run commands directly. It delegates coherent work when a
separate context is useful:

| Agent | Responsibility | Tools |
| --- | --- | --- |
| orchestrate-local | Lead engineer and integration; default | Read, search, edit, shell, task |
| explore | Bounded investigation across unfamiliar source | Read and search |
| implementer | One implementation unit, including investigation and focused tests | Read, search, edit, shell |
| reviewer | Independent correctness assessment and focused verification | Read, search, shell; no edit tools |
| code-local | Direct coding without delegation; comparison/control profile | Read, search, edit, shell |
| orchestrate-frontier | Optional paid lead with the same local workers | Same as local lead |
| raw | Chat and creative writing | No tools |

The lead handles trivial work itself. For substantial work it delegates an
implementation unit, integrates the result, and asks the reviewer to check
nontrivial behavioral changes. A reviewer reports concrete bugs or verification
gaps; it does not start another edit/review loop on its own.

Workers cannot call the Task tool. Explore has 16 steps, implementer 40 and
reviewer 20. The lead has no fixed step cap: a worker limit produces a handoff,
not an unfinished overall task. These caps bound individual delegations, not
total elapsed time.

The backend has one inference slot. The prompt requires one worker at a time;
this is an instruction, not a scheduler lock. Independent reads/searches can
still be batched with parallel tool calls. Shell permissions for implementer and
reviewer allow test execution. A reviewer is instructed not to mutate source;
this is not an operating-system read-only sandbox.

## Local model settings

The main model remains Qwen3.6-35B-A3B IQ4_XS with its Q8 MTP head, served on
127.0.0.1:8080. Its 64K context, 16K output ceiling, Q8 KV cache, CPU/GPU split,
speculation and host prompt cache are retained. DRY remains disabled following
the earlier path-corruption investigation.

Coding agents use temperature 0.6 and top-p 0.95 explicitly. Model options also
supply those defaults. The running template reports no support for graded
reasoning effort: low/medium/high were not distinct reasoning budgets here.
The local variants are now:

- `thinking`: native `chat_template_kwargs.enable_thinking=true` (default).
- `off`: native `chat_template_kwargs.enable_thinking=false`.

Keep thinking enabled for coding and review. Off is an explicit option for
simple chat/experiments, not an automatic fallback. Reasoning is mapped back to
the model's `reasoning_content` field across tool calls.

Titles use the separate CPU-only Qwen3-4B service on 8081. Compaction and summaries
stay on the main local model. Existing compaction and tool-output limits remain.

## Optional frontier use

Select `orchestrate-frontier` explicitly to use the existing
`openai/gpt-5.6-terra` coordinator. It can see source and execute tools directly,
so this profile may send source contents and tool output to the API. Its three
workers remain local.

The local lead has no permitted frontier worker. There is no automatic paid
fallback. The OpenAI key is still read from the private environment through
`OPENAI_API_KEY`; do not put credentials in this repository.

## Memory and integration

Automatic harness-memory loading is disabled. Existing memory databases and
cached packages are retained. This keeps the coding workflow's context explicit
and makes a clean trial closer to ordinary use. The TUI token tracker and
configured language servers remain enabled.

Configuration lives under `users/yejashi/opencode/` and is deployed by the
existing Home Manager `home.file` entry. A running OpenCode server may retain
configuration in existing project instances; activate and reload before starting
a new session. Existing conversations retain their old context and should not be
used as a clean comparison of these prompts.

## Why this replaces the old workflow

The old lead had to hand off edits and shell commands separately. A worker could
make an edit but could not test it; a tester could execute a command but could
not investigate source with file tools. This forced the lead to coordinate small
operations instead of assigning complete units of work.

The new lead can resolve integration issues directly, and the implementer owns
the local investigate/edit/test cycle. Independent review adds a separate check
where correctness warrants it. Prompts no longer force an edit after a numeric
read budget, forbid useful re-reading, or refer to removed workflow sections.

## Evidence and limits

### Local acceptance check, 2026-09-15

A disposable Python cache task exercised falsy values, zero/negative TTLs,
expiration boundaries, regression tests and documentation. Both configurations
used the same starting files and request, the local model only, no memory plugin,
and a seven-minute cap. Runs were sequential on the same server.

| Configuration | Completed | Wall time | Model requests | Agent's tests | Independent contract checks |
| --- | --- | --- | --- | --- | --- |
| Previous orchestration | Yes | 378.8 s | 31 | 13 passed | 10 passed |
| New lead workflow | Yes | 178.1 s | 12 | 17 passed | 10 passed |

The new lead handled this small task directly. This checks the fast path; it
does not establish that delegation improves harder tasks. A single stochastic
trial also cannot establish a general speedup or a SWE-bench resolve rate.

A separate delegation acceptance task required implementer to fix a numeric
mean function for one-shot iterables and empty input, run its tests, and hand
off to reviewer. Both worker calls completed in sequence and the lead finished
in 262.8 seconds. The five project tests and three independent checks passed;
the reviewer reported no correctness findings. Delegation was explicitly
requested in this test, so it verifies the worker path, not automatic routing.

Transport tests against a disposable local API confirmed both thinking variants,
temperature 0.6, top-p 0.95, the 16384-token output limit, tool availability and
reasoning_content preservation across a tool call. OpenCode's own skill loader
accepted the updated NixOS skill and its OpenCode-specific metadata.

### Earlier benchmark

The earlier oc-bench pilot solved 8/20 tasks in 6.9 hours, with gold patches
passing 20/20. That is a baseline for the old configuration.

The earlier three-task v3-read spot check reduced median requests but increased
total requests from 135 to 144 and total time from 25.3 to 39.2 minutes. All three
tasks remained unresolved. It did not establish a success-rate improvement.

For the next SWE-bench comparison, freeze each run's exact configuration and
server settings. The existing runner rewrites its config snapshot and run.json
on resume, so do not change configuration partway through a run. Compare solved
tasks, total/median wall time and timeouts. Its request-start gaps include tool
time; they are not a measurement of pure inference latency.

Upstream references:
[agent configuration](https://opencode.ai/docs/agents/),
[permissions](https://opencode.ai/docs/permissions/),
[llama.cpp request handling](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/server-common.cpp).
