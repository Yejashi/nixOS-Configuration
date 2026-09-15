#!/usr/bin/env bash
# Compare speculative-decoding configs for Qwen3.6-35B-A3B on this host.
#
# The 19GB target does not fit in 12GB of VRAM twice, so the production
# llama-cpp service is stopped for the duration and restarted at the end
# (including on Ctrl-C or error). Polkit allows this without root.
#
#   ~/.cache/llama-drafters/bench-spec.sh
#
# Results go to stdout and to $OUT below.

set -uo pipefail

PATH=/run/current-system/sw/bin:$PATH   # root lacks the home-manager profile
PY=/run/current-system/sw/bin/python3

BIN=/nix/store/5adnwm1vyyb21lpvx2hh5ypwis0jrw0h-llama-cpp-0.4.0/bin/llama-server
MODEL=/var/lib/llama-models/Qwen3.6-35B-A3B-MTP-IMAT-IQ4_XS-Q8nextn.gguf
DRAFTERS=${DRAFTERS:-$HOME/.cache/llama-drafters}  # only needed for dspark/dflash configs
PORT=8099
OUT=${OUT:-${TMPDIR:-/tmp}/llama-spec-results-$(date +%Y%m%d-%H%M%S).tsv}
LOGDIR=$(mktemp -d)
NPREDICT=${NPREDICT:-512}

# Production flags, copied from systemd ExecStart. Everything that is not the
# speculative config is held constant so the comparison isolates it.
BASE=(
  --host 127.0.0.1 --port "$PORT" -m "$MODEL"
  -c 65536 -fa on -ctk q8_0 -ctv q8_0
  -ub 1024 -ngl 999 --load-mode none --fit off
  --jinja --reasoning-preserve
  --min-p 0.0 --temp 0.6
  --cache-ram 18432 --slot-prompt-similarity 1
  --threads 8 --metrics --timeout 0
)

# name : extra flags. "none" is the no-speculation control.
CONFIGS=(
  # Default: locate the --spec-draft-n-max cliff. Add dspark/dflash rows by
  # dropping drafter GGUFs in $DRAFTERS and appending e.g.
  #   "dspark-n2|--n-cpu-moe 24 -md $DRAFTERS/DSPARK-Q8_0.gguf -ngld 999 \
  #     --spec-type draft-dspark --spec-draft-n-max 2"
  "none @24|--n-cpu-moe 24"
  "mtp-n4 @24|--n-cpu-moe 24 --spec-type draft-mtp --spec-draft-n-max 4 --spec-draft-p-min 0.6"
  "mtp-n5 @24|--n-cpu-moe 24 --spec-type draft-mtp --spec-draft-n-max 5 --spec-draft-p-min 0.6"
  "mtp-n6 @24|--n-cpu-moe 24 --spec-type draft-mtp --spec-draft-n-max 6 --spec-draft-p-min 0.6"
  "mtp-n7 @24|--n-cpu-moe 24 --spec-type draft-mtp --spec-draft-n-max 7 --spec-draft-p-min 0.6"
  "mtp-n8 @24|--n-cpu-moe 24 --spec-type draft-mtp --spec-draft-n-max 8 --spec-draft-p-min 0.6"
)

# Coding-shaped prompts: this host serves OpenCode agents, not chat. Two of
# these deliberately repeat verbatim identifiers and paths, which is where
# draft acceptance is highest and where the DRY corruption bit before.
PROMPTS=(
  "Write a Python function merge_intervals(intervals) that merges overlapping closed intervals and returns them sorted. Include a docstring and three doctests."
  "Return ONLY strict JSON, no prose: an object with keys \"name\", \"version\", \"dependencies\" (array of 5 objects each with \"pkg\" and \"constraint\"). Use realistic Python packaging values."
  "In a NixOS flake, rewrite this to use an overlay instead: environment.systemPackages = [ pkgs.ripgrep pkgs.fd pkgs.bat ]; Explain each line you change."
  "Refactor this for readability, keeping the name process_user_record_batch everywhere it appears: def process_user_record_batch(records):\n    out=[]\n    for r in records:\n        if r.get('active') and r.get('email'):\n            out.append({'id':r['id'],'email':r['email'].lower()})\n    return out"
)

SERVICE_WAS_ACTIVE=${RESTORE_SERVICE:-1}
PID=""

cleanup() {
  [[ -n $PID ]] && kill "$PID" 2>/dev/null && wait "$PID" 2>/dev/null
  if [[ $SERVICE_WAS_ACTIVE == 1 ]]; then
    echo "==> restoring llama-cpp service"
    systemctl start llama-cpp
  fi
}
trap cleanup EXIT INT TERM

# Root is not required: polkit permits managing llama-cpp as the local user.
for f in "$MODEL" "$BIN"; do
  [[ -r $f ]] || { echo "missing: $f" >&2; exit 1; }
done

vram_used_mib() {
  local u
  u=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | sort -rn | head -1)
  echo $(( ${u:-0} / 1048576 ))
}

if systemctl is-active --quiet llama-cpp; then
  echo "==> stopping llama-cpp to free VRAM"
  systemctl stop llama-cpp
  sleep 3
fi

printf 'config\tstatus\ttok_s\tgen_tokens\twall_s\tacceptance\tmean_len\tvram_mib\n' | tee "$OUT"

for entry in "${CONFIGS[@]}"; do
  name=${entry%%|*}
  extra=${entry#*|}
  log=$LOGDIR/${name// /_}.log

  # shellcheck disable=SC2086
  "$BIN" "${BASE[@]}" $extra >"$log" 2>&1 &
  PID=$!

  # Wait for readiness; a VRAM-starved config dies here instead of hanging.
  ready=0
  for _ in $(seq 1 180); do
    if ! kill -0 "$PID" 2>/dev/null; then break; fi
    if curl -sf --max-time 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then ready=1; break; fi
    sleep 2
  done

  if [[ $ready == 0 ]]; then
    reason=$(grep -ioE "out of memory|failed to allocate|unsupported|unknown argument[^\"]*|error[^\"]*" "$log" | tail -1)
    printf '%s\tFAILED: %s\t-\t-\t-\t-\t-\t-\n' "$name" "${reason:-did not become ready}" | tee -a "$OUT"
    kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null; PID=""
    cp "$log" "$DRAFTERS/failed-${name// /_}.log" 2>/dev/null
    continue
  fi

  vram=$(vram_used_mib)

  # One untimed warmup so the first prompt does not pay graph/cache setup.
  curl -sf --max-time 300 "http://127.0.0.1:$PORT/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"messages":[{"role":"user","content":"hi"}],"max_tokens":16,"stream":false}' >/dev/null 2>&1

  total_tok=0
  total_s=0
  for p in "${PROMPTS[@]}"; do
    body=$("$PY" -c 'import json,sys
print(json.dumps({"messages":[{"role":"user","content":sys.argv[1]}],
                  "max_tokens":int(sys.argv[2]),"stream":False,"seed":42}))' "$p" "$NPREDICT")
    t0=$(date +%s.%N)
    resp=$(curl -sf --max-time 600 "http://127.0.0.1:$PORT/v1/chat/completions" \
      -H 'Content-Type: application/json' -d "$body")
    t1=$(date +%s.%N)
    [[ -z $resp ]] && continue
    tok=$(printf '%s' "$resp" | "$PY" -c 'import json,sys
try: print(json.load(sys.stdin).get("usage",{}).get("completion_tokens",0) or 0)
except Exception: print(0)')
    total_tok=$(( total_tok + tok ))
    total_s=$("$PY" -c "print($total_s + $t1 - $t0)")
  done

  # Acceptance comes from the server's own print_timing lines, averaged over
  # this config's requests only (fresh log per config).
  read -r acc mlen < <(grep -oE "draft acceptance = [0-9.]+ .* mean len = *[0-9.]+" "$log" \
    | awk '{for(i=1;i<=NF;i++){if($i=="acceptance")a+=$(i+2);if($i=="len")m+=$(i+2)}n++}
           END{if(n)printf "%.3f %.2f\n", a/n, m/n; else print "-  -"}')

  tok_s=$("$PY" -c "print(f'{($total_tok/$total_s):.1f}' if $total_s>0 else '-')")
  printf '%s\tok\t%s\t%s\t%.1f\t%s\t%s\t%s\n' \
    "$name" "$tok_s" "$total_tok" "$total_s" "${acc:--}" "${mlen:--}" "$vram" | tee -a "$OUT"

  kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null; PID=""
  sleep 3
done

echo
echo "results: $OUT"
echo "server logs: $LOGDIR"
