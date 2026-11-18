#!/usr/bin/env bash
# run-tests.sh — regression tests for the scripts in ../, with fake codex and
# devin binaries. No model is called and no network is used.
#
# Usage: scripts/tests/run-tests.sh      (exit 0 = all passed)
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
scripts=$(dirname "$here")
work=$(mktemp -d "${TMPDIR:-/tmp}/mmc-tests.XXXXXX")
trap 'rm -rf "$work"' EXIT
pass=0 failed=0
ok() { echo "ok   $1"; pass=$((pass + 1)); }
bad() { echo "FAIL $1"; failed=$((failed + 1)); }
check() { local name=$1; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }

# --- fake tools -------------------------------------------------------------
# Fake codex: behaviour chosen by $FAKE_CODEX (ok | fail | silent).
mkdir -p "$work/bin"
cat > "$work/bin/codex" <<'EOF'
#!/usr/bin/env bash
case ${FAKE_CODEX:-ok} in
  silent) sleep 30; exit 0 ;;
  fail) echo "session id: fake"; echo "error: 429 quota"; exit 1 ;;
  *) echo "session id: fake"; echo "thinking..."; echo "tokens used"; echo "1,234"; echo "GPT FINDING: P2 a.go:1"; exit 0 ;;
esac
EOF
# Fake devin: behaviour chosen by $FAKE_DEVIN (ok | provider_down | empty).
cat > "$work/bin/devin" <<'EOF'
#!/usr/bin/env bash
case ${FAKE_DEVIN:-ok} in
  provider_down) echo "Error: Agent error: Permission denied: The third-party model provider is experiencing issues" >&2; exit 1 ;;
  empty) exit 0 ;;
  *) echo "GEMINI FINDING: P1 b.go:2"; exit 0 ;;
esac
EOF
chmod +x "$work/bin/codex" "$work/bin/devin"
export CODEX_BIN=$work/bin/codex DEVIN_BIN=$work/bin/devin CODEX_REVIEW=$scripts/codex-review START_WAIT=4
export REVIEW_TIMEOUT=60

# A small repository with a baseline and one candidate commit on a named branch.
repo=$work/repo
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m base
git -C "$repo" checkout -q -b secret-implementer-branch
echo 'package a' > "$repo/a.go"; mkdir -p "$repo/docs"; echo note > "$repo/docs/n.md"
git -C "$repo" add -A && git -C "$repo" -c user.name=t -c user.email=t@t commit -q -m "implementer: round 1"
echo '{}' > "$work/cfg.json"; echo "review this" > "$work/prompt.txt"
dual() { "$scripts/run-dual-review.sh" "$repo" "$work/prompt.txt" "$work/out/A" "$work/cfg.json" >/dev/null 2>&1; }
merge() { python3 -I "$scripts/merge-findings.py" --prefix "$work/out/A" --out "$work/out/findings.md" --mapping "$work/out/map.txt" --label A --seed 1 >/dev/null 2>&1; }

# 1. Both reviewers succeed: exit 0, merge works, both answers present, no tool noise.
dual; check "dual review succeeds when both reviewers succeed" test $? -eq 0
merge; check "merge succeeds after a clean run" test $? -eq 0
check "merged file holds both answers" grep -q 'GPT FINDING' "$work/out/findings.md"
check "merged file holds the Gemini answer" grep -q 'GEMINI FINDING' "$work/out/findings.md"
check "merged file has no Codex log lines" bash -c "! grep -q 'tokens used' '$work/out/findings.md'"
check "run record names the reviewed commit" grep -q "head=$(git -C "$repo" rev-parse HEAD)" "$work/out/A-gem.run"

# 2. Gemini provider outage: dual fails, the error is not in the answer file, merge refuses.
FAKE_DEVIN=provider_down dual; check "dual review fails when Gemini fails" test $? -ne 0
check "Gemini error goes to the log, not the answer" bash -c "! grep -q 'provider' '$work/out/A-gem.txt' && grep -q 'provider' '$work/out/A-gem.log'"
merge; check "merge refuses a failed Gemini review" test $? -ne 0

# 3. Retry only Gemini with the same prefix: the earlier failure must not stick.
REVIEWERS=gem dual; check "retrying only Gemini succeeds after an earlier failure" test $? -eq 0
merge; check "merge succeeds after the retry" test $? -eq 0
check "history keeps the failed run for the record" grep -q '^gem exit=1' "$work/out/A-history.txt"

# 4. Empty Gemini answer with exit 0 is not a review.
FAKE_DEVIN=empty REVIEWERS=gem dual; check "empty Gemini answer counts as failure" test $? -ne 0
merge; check "merge refuses an empty Gemini answer" test $? -ne 0
REVIEWERS=gem dual >/dev/null

# 5. Codex quota error and Codex that never starts.
FAKE_CODEX=fail REVIEWERS=gpt dual; check "dual review fails when Codex fails" test $? -ne 0
merge; check "merge refuses a failed GPT review" test $? -ne 0
FAKE_CODEX=silent "$scripts/codex-review" -t 60 -o "$work/silent.txt" "x" >/dev/null 2>&1
check "codex-review exits 3 when Codex never starts" test $? -eq 3
"$scripts/codex-review" -o "$work/okay.txt" "x" > "$work/okay.stdout" 2>&1
check "codex-review prints the final answer" grep -q 'GPT FINDING' "$work/okay.stdout"

# 6. make-blind-copy hides the implementer's branch name and keeps the tree.
"$scripts/make-blind-copy.sh" "$repo" main "$work/copy" secret-implementer-branch >/dev/null 2>&1
check "blind copy builds" test -d "$work/copy/.git"
check "blind copy has no implementer branch name" bash -c "! git -C '$work/copy' for-each-ref | grep -q secret; ! git -C '$work/copy' log --all --format=%s | grep -q implementer"
check "blind copy has the candidate tree" test -f "$work/copy/a.go"

# 7. check-scope flags out-of-scope files, including untracked ones.
printf '# allowed\n*.go\n' > "$work/allowed.txt"
"$scripts/check-scope.sh" "$repo" main "$work/allowed.txt" > "$work/scope.txt"
check "check-scope fails on an out-of-scope file" test $? -eq 1
check "check-scope names the file" grep -q 'docs/n.md' "$work/scope.txt"
printf '*.go\ndocs/*\n' > "$work/allowed.txt"
echo x > "$repo/stray.txt"
"$scripts/check-scope.sh" "$repo" main "$work/allowed.txt" > "$work/scope.txt"
check "check-scope reports untracked files" grep -q 'stray.txt' "$work/scope.txt"
rm "$repo/stray.txt"
"$scripts/check-scope.sh" "$repo" main "$work/allowed.txt" >/dev/null
check "check-scope passes when everything is in scope" test $? -eq 0

echo "passed $pass, failed $failed"
[ "$failed" -eq 0 ]
