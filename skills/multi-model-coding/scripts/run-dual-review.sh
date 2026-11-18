#!/usr/bin/env bash
# run-dual-review.sh — run the GPT and Gemini reviews of one blind copy in parallel.
#
# Usage:
#   run-dual-review.sh <copy-dir> <prompt-file> <out-prefix> <devin-config> [<gemini-model>]
#
# Writes, per reviewer (gpt, gem), overwriting the previous run of that reviewer:
#   <out-prefix>-gpt.txt        full Codex log (codex-review -o)
#   <out-prefix>-gpt.stdout     codex-review's own output (final answer + exit line)
#   <out-prefix>-gem.txt        Devin's final answer (stdout of `devin -p` only)
#   <out-prefix>-gem.log        Devin's stderr (errors, provider failures)
#   <out-prefix>-gem-conversation.md   Devin export (tokens, session id)
#   <out-prefix>-<who>.status   one line: "exit=<rc> start=<t> end=<t>" for the
#                               latest run of that reviewer; merge-findings.py
#                               refuses to merge unless both say exit=0
#   <out-prefix>-<who>.run      run record: copy HEAD, prompt sha256, model,
#                               effort, exit code, times
# and appends one line per reviewer run to <out-prefix>-history.txt (kept for
# the record only; it is never used to decide success).
#
# Exit status: 0 only when every reviewer started by THIS run exited 0.
# To redo only one reviewer (for example after a provider outage), set
# REVIEWERS=gem or REVIEWERS=gpt; the other reviewer's files are left alone.
#
# Run it detached or as a background job and wait for its exit; a non-zero
# exit for a reviewer means that review did not happen.
#
# Requires: codex-review (scripts/codex-review, or CODEX_REVIEW=<path>), the
# devin CLI with bubblewrap + socat for --sandbox. <devin-config> must be
# read-only for the workspace (see devin-readonly.example.json).
#
# Environment: REVIEWERS (default "gpt gem"), GPT_EFFORT (default xhigh),
# REVIEW_TIMEOUT seconds (default 3600), CODEX_REVIEW, DEVIN_BIN (default devin).
# TMPDIR is passed through to both tools.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ $# -lt 4 ]; then
  sed -n '2,35p' "$0" >&2
  exit 2
fi
copy=$1 prompt=$2 out=$3 cfg=$4 gem_model=${5:-gemini-4-argon-high}
effort=${GPT_EFFORT:-xhigh}
limit=${REVIEW_TIMEOUT:-3600}
reviewers=${REVIEWERS:-gpt gem}
codex_review=${CODEX_REVIEW:-}
if [ -z "$codex_review" ]; then
  if command -v codex-review >/dev/null 2>&1; then codex_review=codex-review; else codex_review=$here/codex-review; fi
fi
devin=${DEVIN_BIN:-devin}
export NO_COLOR=1

for f in "$prompt" "$cfg"; do
  [ -f "$f" ] || { echo "run-dual-review: missing $f" >&2; exit 2; }
done
for r in $reviewers; do
  case $r in gpt|gem) ;; *) echo "run-dual-review: unknown reviewer '$r' (gpt, gem)" >&2; exit 2 ;; esac
done
git -C "$copy" rev-parse --git-dir >/dev/null 2>&1 || { echo "run-dual-review: $copy is not a git repository" >&2; exit 2; }
prompt=$(realpath "$prompt"); cfg=$(realpath "$cfg")
out=$(realpath -m "$out"); mkdir -p "$(dirname "$out")"
head_sha=$(git -C "$copy" rev-parse HEAD)
prompt_sha=$(sha256sum "$prompt" | cut -d' ' -f1)

# finish <who> <rc> <start> <model> <effort>: write status, run record, history.
finish() {
  local who=$1 rc=$2 s=$3 m=$4 e=$5 end
  end=$(date +%FT%T)
  printf 'exit=%s start=%s end=%s\n' "$rc" "$s" "$end" > "$out-$who.status"
  printf 'reviewer=%s\nmodel=%s\neffort=%s\ncopy=%s\nhead=%s\nprompt=%s\nprompt_sha256=%s\nexit=%s\nstart=%s\nend=%s\n' \
    "$who" "$m" "$e" "$copy" "$head_sha" "$prompt" "$prompt_sha" "$rc" "$s" "$end" > "$out-$who.run"
  printf '%s exit=%s start=%s end=%s head=%s\n' "$who" "$rc" "$s" "$end" "${head_sha:0:12}" >> "$out-history.txt"
}

pids=()
for r in $reviewers; do
  # A stale status from an earlier run must not survive this one.
  rm -f "$out-$r.status"
  case $r in
  gpt)
    (
      cd "$copy" || exit 2
      s=$(date +%FT%T)
      "$codex_review" -e "$effort" -t "$limit" -o "$out-gpt.txt" "$(cat "$prompt")" > "$out-gpt.stdout" 2>&1
      finish gpt $? "$s" "${GPT_MODEL:-gpt-6.1-sol}" "$effort"
    ) &
    pids+=($!) ;;
  gem)
    (
      cd "$copy" || exit 2
      s=$(date +%FT%T)
      timeout "$limit" "$devin" --config "$cfg" --model "$gem_model" --sandbox --respect-workspace-trust false \
        --export "$out-gem-conversation.md" --prompt-file "$prompt" -p < /dev/null > "$out-gem.txt" 2> "$out-gem.log"
      rc=$?
      # An empty answer is not a review even when the tool exits 0.
      [ "$rc" -eq 0 ] && [ ! -s "$out-gem.txt" ] && rc=65
      finish gem $rc "$s" "$gem_model" -
    ) &
    pids+=($!) ;;
  esac
done
for p in "${pids[@]}"; do wait "$p"; done

fail=0
for r in $reviewers; do
  line=$(cat "$out-$r.status" 2>/dev/null || echo "exit=missing")
  echo "$r $line"
  case $line in exit=0\ *) ;; *) fail=1 ;; esac
done
exit $fail
