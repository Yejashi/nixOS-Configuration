#!/usr/bin/env bash
# Tune llama-cpp for PROMPT processing, not generation.
#
# The generation-focused sweep (llama-bench-spec.sh) optimised the wrong metric:
# measured over real agent traffic, 90% of wall time is prompt eval and under
# 10% is token generation. Prompt eval averaged 57.7 tok/s against ~480 tok/s
# when the work stays on the GPU.
#
# Cause is --n-cpu-moe. The model is 41 layers, 256 experts, 8 used per token:
# generating touches 3% of the expert weights (CPU copes), but a 1024-token
# prompt batch activates nearly all of them, so the offloaded layers become a
# dense GEMM on 8 cores over DDR4.
#
# Measured 2026-09-15: the current moe24-c64k does 536 tok/s prompt eval on an
# otherwise-idle GPU but leaves only 870 MiB of VRAM headroom. A real desktop
# takes ~940 MiB, which pushes the model over the edge into GTT and collapses
# prompt eval roughly tenfold. Headroom, not expert placement, is the variable
# that matters.
#
# KV measured at ~14.6 KB/token (468 MiB per 32768), so shrinking -c buys very
# little - and with kv_unified the pool is shared across all slots, so a smaller
# -c just makes agents evict each other. This sweep therefore holds -c at 65536
# and buys headroom by moving expert layers to the CPU: ~818 MiB per 2 layers,
# at roughly 2.5% prompt speed.
#
# The production service is stopped for the duration and restarted at the end,
# including on Ctrl-C or error.
#
# RUN THIS FROM YOUR OWN TERMINAL. Stopping llama-cpp prompts for your password
# via polkit, so it needs an active local session with a way to ask. A detached
# or agent-spawned shell is refused outright ("interactive authentication
# required"), and without the guard below such a run silently measures two
# models competing for 12GB rather than the configuration under test. The older
# llama-bench-spec.sh claims this works without root; it does not.
#
# Leave the desktop session running: VRAM headroom under an idle GNOME is not
# the headroom that matters.

set -uo pipefail
PATH=/run/current-system/sw/bin:$PATH
PY=/run/current-system/sw/bin/python3

BIN=/nix/store/5adnwm1vyyb21lpvx2hh5ypwis0jrw0h-llama-cpp-0.4.0/bin/llama-server
MODEL=/var/lib/llama-models/Qwen3.6-35B-A3B-MTP-IMAT-IQ4_XS-Q8nextn.gguf
REPO=/home/yejashi/Documents/repos/nixOS-Configuration
PORT=8099
OUT=${OUT:-$HOME/.cache/llama-drafters/bench-prompt-$(date +%Y%m%d-%H%M%S).tsv}
LOGDIR=$(mktemp -d)

# Held constant. Speculation stays on at the measured optimum so the numbers
# describe the configuration actually served.
BASE=(
  --host 127.0.0.1 --port "$PORT" -m "$MODEL"
  -fa on -ctk q8_0 -ctv q8_0 -ngl 999 --load-mode none --fit off
  --spec-type draft-mtp --spec-draft-n-max 6 --spec-draft-p-min 0.6
  --jinja --reasoning-preserve --min-p 0.0 --temp 0.6
  --slot-prompt-similarity 0.5 --threads 8 --metrics --timeout 0
)

# name | ctx | n-cpu-moe | ubatch | extra
CONFIGS=(
  "moe26-c64k|65536|26|1024|"
  "moe28-c64k|65536|28|1024|"
  "moe30-c64k|65536|30|1024|"
  "moe32-c64k|65536|32|1024|"
  "moe28-c64k-par4|65536|28|1024|--parallel 4 -kvu"
)


PID=""
cleanup() {
  [[ -n $PID ]] && kill "$PID" 2>/dev/null && wait "$PID" 2>/dev/null
  echo "==> restoring llama-cpp service"
  systemctl start llama-cpp
}
trap cleanup EXIT INT TERM

VRAM_TOTAL=$(( $(cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | sort -rn | head -1) / 1048576 ))

vram_mib() {
  local u; u=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | sort -rn | head -1)
  echo $(( ${u:-0} / 1048576 ))
}

# Agent-shaped prompts: a large body of real source plus a short question, the
# shape that actually hits this server. Each is distinct so nothing is served
# from a reused prefix - a cache miss is the case being measured.
build_prompts() {
  "$PY" - "$REPO" <<'PYEOF'
import json, sys, pathlib
repo = pathlib.Path(sys.argv[1])
def rd(p):
    try: return (repo/p).read_text()
    except Exception: return ""
big   = rd("system/configuration.nix")
home  = rd("users/yejashi/home.nix")
oc    = rd("users/yejashi/opencode/opencode.json")
cases = [
  ("large ~9k", big + "\n\n" + home,
   "Name every systemd service defined above and say in one line what each does."),
  ("medium ~4k", home,
   "List the home.packages entries above. One line, comma separated."),
  ("small ~2k", oc,
   "Which agents above have webfetch allowed? Answer with a bare list."),
]
out=[]
for name, body, q in cases:
    out.append({"name": name,
                "content": f"Here is configuration from a NixOS repository.\n\n```\n{body}\n```\n\n{q}"})
print(json.dumps(out))
PYEOF
}

PROMPTS_JSON=$(build_prompts)

# The 19GB target does not fit in 12GB of VRAM twice. Without this the bench
# server starts starved and every number measures contention instead of the
# configuration under test.
if systemctl is-active --quiet llama-cpp; then
  echo "==> stopping llama-cpp to free VRAM"
  if ! systemctl stop llama-cpp; then
    echo "ERROR: could not stop llama-cpp. Run this from an interactive" >&2
    echo "terminal; results are meaningless while the 35B still holds VRAM." >&2
    exit 1
  fi
  sleep 5
fi
for _ in $(seq 1 30); do
  used=$(vram_mib); [[ $used -lt 3000 ]] && break; sleep 2
done
echo "==> VRAM before first config: $(vram_mib) MiB"

printf 'config\tstatus\tprompt\tprompt_tok\tprompt_s\tprompt_tok_s\tgen_tok\tgen_s\ttotal_s\tvram_mib\theadroom\n' | tee "$OUT"

for entry in "${CONFIGS[@]}"; do
  IFS='|' read -r name ctx moe ub extra <<<"$entry"
  log=$LOGDIR/${name// /_}.log

  # shellcheck disable=SC2086
  "$BIN" "${BASE[@]}" -c "$ctx" --n-cpu-moe "$moe" -ub "$ub" $extra >"$log" 2>&1 &
  PID=$!

  ready=0
  for _ in $(seq 1 180); do
    kill -0 "$PID" 2>/dev/null || break
    curl -sf --max-time 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && { ready=1; break; }
    sleep 2
  done

  if [[ $ready == 0 ]]; then
    reason=$(grep -ioE "out of memory|failed to allocate|unable to allocate|unsupported|error[^\"]*" "$log" | tail -1)
    printf '%s\tFAILED: %s\t-\t-\t-\t-\t-\t-\t-\t-\t-\n' "$name" "${reason:-did not become ready}" | tee -a "$OUT"
    kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null; PID=""
    cp "$log" "$LOGDIR/failed-${name// /_}.log" 2>/dev/null
    continue
  fi

  vram=$(vram_mib)

  n=$("$PY" -c "import json,sys;print(len(json.loads(sys.argv[1])))" "$PROMPTS_JSON")
  for i in $(seq 0 $((n-1))); do
    pname=$("$PY" -c "import json,sys;print(json.loads(sys.argv[1])[int(sys.argv[2])]['name'])" "$PROMPTS_JSON" "$i")
    body=$("$PY" -c "
import json,sys
p=json.loads(sys.argv[1])[int(sys.argv[2])]
print(json.dumps({'messages':[{'role':'user','content':p['content']}],
                  'max_tokens':200,'stream':False,'seed':42,
                  'chat_template_kwargs':{'enable_thinking':False}}))" "$PROMPTS_JSON" "$i")

    t0=$(date +%s.%N)
    curl -sf --max-time 900 "http://127.0.0.1:$PORT/v1/chat/completions" \
      -H 'Content-Type: application/json' -d "$body" >/dev/null 2>&1
    t1=$(date +%s.%N)
    total=$("$PY" -c "print(f'{$t1-$t0:.1f}')")

    # Server timings are authoritative for the prompt/generation split.
    read -r ptok ps gtok gs < <(tail -40 "$log" | "$PY" -c "
import re,sys
ptok=ps=gtok=gs='-'
for l in sys.stdin:
    m=re.search(r'prompt eval time = *([0-9.]+) ms / *(\d+)',l)
    if m: ps,ptok=f'{float(m.group(1))/1000:.1f}',m.group(2)
    if 'prompt eval time' not in l:
        m=re.search(r'\beval time = *([0-9.]+) ms / *(\d+)',l)
        if m: gs,gtok=f'{float(m.group(1))/1000:.1f}',m.group(2)
print(ptok,ps,gtok,gs)")

    pts=$("$PY" -c "
try: print(f'{int('$ptok')/float('$ps'):.1f}')
except Exception: print('-')" 2>/dev/null || echo '-')

    printf '%s\tok\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$name" "$pname" "$ptok" "$ps" "$pts" "$gtok" "$gs" "$total" "$vram" "$((VRAM_TOTAL-vram))" | tee -a "$OUT"
  done

  kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null; PID=""
  sleep 5
done

echo
echo "results: $OUT"
echo "logs:    $LOGDIR"
