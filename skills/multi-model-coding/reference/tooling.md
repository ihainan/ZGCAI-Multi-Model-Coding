# Tools and Commands

## Contents

1. Codex implementer
2. Codex reviewer (codex-review)
3. Devin implementer, reviewer and verifier
4. Background execution and waiting
5. Environment isolation
6. Known pitfalls

Commands were tested with Codex CLI 0.167 and Devin CLI 3000.12 (2026-11-12). Angle brackets are placeholders; directories, caches and test services come from the project's environment profile (templates.md section 7). The skill currently depends on Codex and Devin; every script takes the binary from an environment variable (`CODEX_BIN`, `DEVIN_BIN`, `CODEX_REVIEW`) so another CLI with the same contract can be substituted.

---

## 1. Codex Implementer

First round:

```bash
cd <worktree> && timeout 21600 codex exec -m gpt-6.1-sol \
  -c model_reasoning_effort=high \
  -c sandbox_mode="workspace-write" \
  -c sandbox_workspace_write.network_access=true \
  -c 'sandbox_workspace_write.writable_roots=["<build cache>","<TMPDIR>"]' \
  -o <out>/final.txt - < <brief.md> > <out>/log.txt 2>&1; echo "$?" > <out>/done.txt
```

- The task brief comes in on stdin (the trailing `-`). Stdin must not be left open and empty, or Codex stops at `Reading additional input from stdin...`.
- The session ID is on the `session id:` line at the top of the log; rework needs it.
- `writable_roots` must include the build cache and temporary directories the profile names, or builds fail with read-only errors. `network_access` is needed when the tests reach services on localhost (databases in containers).
- Write the exit code to a file of its own (`done.txt` above) and wait on that.
- `tokens used` is at the end of the log; after a resume the number may be the session total.

Rework (resuming the original session):

```bash
cd <worktree> && timeout 21600 codex exec resume <session-id> -m gpt-6.1-sol \
  -c model_reasoning_effort=high -c sandbox_mode="workspace-write" \
  -c 'sandbox_workspace_write.writable_roots=[...]' \
  -o <out>/r2-final.txt - < <rework.md> > <out>/r2-log.txt 2>&1
```

## 2. Codex Reviewer (codex-review)

```bash
cd <blind-copy> && scripts/codex-review -e xhigh -o <out>/gpt-X.txt "$(cat <review-prompt.txt>)"
```

- `scripts/codex-review` ships with the skill. It runs Codex read-only, connects stdin to `/dev/null`, exits 3 if Codex has not started within 90 seconds, exits 124 on timeout, and prints only the final answer.
- It must run inside a git repository (Codex requires one). Treat any non-zero exit code as "not reviewed": 3 = never started, 124 = timed out, anything else = error (quota 429 and the like).
- The final answer follows the last `tokens used` line and its count line in the full log; `scripts/merge-findings.py` extracts it that way.
- Use `-e xhigh` for spec reviews, security, concurrency, migrations, billing or large changes; `-e high` for fix checks and ordinary changes.

## 3. Devin Implementer, Reviewer and Verifier

```bash
cd <worktree> && timeout 3600 devin --config <cfg.json> --model gemini-4-argon-high \
  --sandbox --respect-workspace-trust false \
  [-r <session-name>] \
  --export <out>/conversation.md --prompt-file <prompt.md> -p < /dev/null > <out>/final.txt 2> <out>/stderr.log
```

- **`--sandbox` is required.** Under `-p`, `--permission-mode accept-edits` rejects every command that is not read-only. `--sandbox` needs bubblewrap and socat.
- **Keep stdout and stderr apart.** Provider errors ("the third-party model provider is experiencing issues") arrive with a non-zero exit; written into the answer file they look like a review. `scripts/run-dual-review.sh` separates them and records the exit code.
- The sandbox can write only to the working directory. Network access is not restricted, so credentials (cluster configs, SSH keys, CLI tokens) must be in the deny list.
- **Implementer config:** in `permissions.allow`, grant `Edit(<worktree>/**)`, `Write(<worktree>/**)` and Write on the build cache directories by path. Never use bare `edit`/`write` without a path, which allows any path.
- **Read-only reviewer config:** grant no workspace Edit/Write at all; see `scripts/devin-readonly.example.json`.
- **Verifier config:** grant Edit/Write only on that verifier's own blind copy, its TMPDIR and the build caches; deny the other copies and the review materials except the findings file. See `scripts/devin-verifier.example.json`. Recommended models: `swe-2-max` (free) or `glm-5-3-high`.
- **TMPDIR must not sit under a read-denied directory.** A verifier whose TMPDIR was under a denied path could not even list it and fell back to a temporary directory inside the repository.
- Disable Devin's built-in `web_search` and `run_subagent` (put them in deny).
- If the config denies reading the directory the prompt file lives in, files the prompt refers to cannot be read; inline their content into `--prompt-file`.
- In `-p` mode stdout stays empty until the end; to check progress, look at Devin's own log directory (`~/.local/share/devin/cli/logs/` on Linux).
- Resuming: the session name is in the `"session_id"` field of the `--export` file; pass it with `-r <session-name>`.
- Token usage is in the export and is cumulative for the session.
- A provider outage can last minutes to hours. Rerun only the failed reviewer (`REVIEWERS=gem scripts/run-dual-review.sh ...`); never merge without it.

`devin models` is the authoritative model list; models marked `Free` do not consume credits.

## 4. Background Execution and Waiting

- Start every implementer, reviewer and verifier as a background job of its own, and wait on that job's completion (the harness's completion notice, an exit-code file the job writes, or its PID). In Claude Code: the Bash tool's `run_in_background`.
- When starting several jobs at once, write a bash script with one subshell per job; each writes its own status file with its exit code, and the script ends with `wait`. Never decide success from a file that earlier runs append to.
- Do not find processes to wait on with `pgrep -f`: it matches the watching command itself, or same-named processes from other sessions.
- When the user asks about progress, read the job's output or log to confirm it is advancing before answering.
- The harness may stop background jobs when the machine runs short of memory; a stopped job is "not done", like a non-zero exit.

## 5. Environment Isolation

- One git worktree and one test database (or schema) per implementer and per tester.
- Blind review copies are independent clones (`scripts/make-blind-copy.sh`), not worktrees: a worktree shares refs with the source repository, so `git branch -a` reveals the implementer's branch name.
- Temporary and cache directories, memory or load limits, and where heavy or timing-sensitive runs happen are in the environment profile; pass the directories to every sandbox's writable paths.
- Agents that must stay offline: point the package cache at its real location and disable downloads (Go: `GOMODCACHE` and `GOPROXY=off`), or the first build silently downloads toolchains and modules.

## 6. Known Pitfalls

- **zsh does not split variables on spaces:** `set -- $p` and `for x in $list` do not split in zsh. Write multi-argument batch commands as bash scripts and pass arguments explicitly.
- **Raw Codex review output is large** (hundreds of KB of tool-call logs): extract only the final answer before merging.
- **Test order dependence:** earlier tests in a package can warm caches so that later tests "pass in the full package, fail alone". Run the tester's tests individually or in random order.
- **Timing tests on a busy machine** fail intermittently and pass when rerun alone. Do not take a failure from a contended machine as evidence of a defect, or a pass as evidence of none; rerun where the profile says timing-sensitive runs belong. One package was suspected of a 1 ms per-request regression for several hours until a controlled A/B rerun showed the difference was load.
- **Devin `--sandbox` leaves socat processes behind:** every run starts a pair of `socat` proxies (listening on `claude-http-*.sock` / `claude-socks-*.sock` under TMPDIR) that are reparented to init and never exit. After a batch, list them with `ps -eo pid=,args= | awk '$2 ~ /socat$/ && /<your TMPDIR>\//'` and kill those exact PIDs; do not use a broad `pkill socat`, which also kills proxies of sessions still running.
- **Content moderation:** avoid words like "adversarial", "bypass" or "leak" in review prompts; Codex may refuse. If needed, split the prompt into parts and run them serially.
- **Reviewers may publish:** a Codex reviewer once deployed its own report with a publishing tool it found on the machine. Every prompt says "do not publish or upload anything".
- **Messaging a subagent while it is being resumed** fails (HTTP 409, "the agent's turn is already being resumed") and the subagent stops; its working files survive. Message a subagent only after its completion notice, and resend once if it stops this way.
- **Implementers make unrelated edits** while fixing something else (one changed a test's Redis database number). Run `scripts/check-scope.sh` on every delivery.
