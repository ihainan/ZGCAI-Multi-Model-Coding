#!/usr/bin/env bash
# run-dual-review.sh — run the GPT and Gemini reviews of one blind copy in parallel.
#
# Usage:
#   run-dual-review.sh <copy-dir> <prompt-file> <out-prefix> <devin-config> [<gemini-model>]
#
# Writes:
#   <out-prefix>-gpt.txt                 full Codex output (codex-review -o)
#   <out-prefix>-gem.txt                 Devin final answer (stdout of -p)
#   <out-prefix>-gem-conversation.md     Devin export (tokens, session id)
#   <out-prefix>-times.txt               "<who> exit=<rc> start <t> end <t>" per reviewer
#
# Run it with the Bash tool's run_in_background and wait for the completion
# notice. A non-zero exit for either reviewer means that review did not happen.
#
# Requires: codex-review on PATH (see reference/tooling.md), devin CLI with
# bubblewrap + socat for --sandbox. <devin-config> must be read-only for the
# workspace (see devin-readonly.example.json).
#
# Environment: GPT_EFFORT (default xhigh), REVIEW_TIMEOUT seconds (default 3600),
# TMPDIR is respected and should point at a data disk, not a RAM-backed /tmp.
set -uo pipefail

if [ $# -lt 4 ]; then
  sed -n '2,22p' "$0" >&2
  exit 2
fi
copy=$1 prompt=$2 out=$3 cfg=$4 gem_model=${5:-gemini-4-argon-high}
effort=${GPT_EFFORT:-xhigh}
limit=${REVIEW_TIMEOUT:-3600}
export NO_COLOR=1

for f in "$prompt" "$cfg"; do
  [ -f "$f" ] || { echo "run-dual-review: missing $f" >&2; exit 2; }
done
git -C "$copy" rev-parse --git-dir >/dev/null 2>&1 || { echo "run-dual-review: $copy is not a git repository" >&2; exit 2; }
prompt=$(realpath "$prompt"); cfg=$(realpath "$cfg")
out=$(realpath -m "$out"); mkdir -p "$(dirname "$out")"

(
  cd "$copy" || exit 2
  s=$(date +%T)
  codex-review -e "$effort" -t "$limit" -o "$out-gpt.txt" "$(cat "$prompt")" > "$out-gpt.stdout" 2>&1
  echo "gpt exit=$? start $s end $(date +%T)" >> "$out-times.txt"
) &
(
  cd "$copy" || exit 2
  s=$(date +%T)
  timeout "$limit" devin --config "$cfg" --model "$gem_model" --sandbox --respect-workspace-trust false \
    --export "$out-gem-conversation.md" --prompt-file "$prompt" -p < /dev/null > "$out-gem.txt" 2>&1
  echo "gem($gem_model) exit=$? start $s end $(date +%T)" >> "$out-times.txt"
) &
wait
cat "$out-times.txt"
# Fail if either reviewer exited non-zero.
! grep -q 'exit=[1-9]' "$out-times.txt"
