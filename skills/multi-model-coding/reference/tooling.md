# Tools and Commands

## Contents

1. Codex implementer
2. Codex reviewer (codex-review)
3. Devin implementer and reviewer
4. Background execution and waiting
5. Environment isolation
6. Known pitfalls

Every command here was tested on 2026-11-12 (Codex CLI 0.167, Devin CLI 3000.12). Paths follow the conventions of the original machine; replace them on other machines.

---

## 1. Codex Implementer

First round:

```bash
cd <worktree> && timeout 5400 codex exec -m gpt-6.1-sol \
  -c model_reasoning_effort=high \
  -c sandbox_mode="workspace-write" \
  -c 'sandbox_workspace_write.writable_roots=["<GOCACHE>","<GOTMPDIR>","<TMPDIR>"]' \
  -o <out>/final.txt - < <brief.md> > <out>/log.txt 2>&1
```

- The task brief comes in on stdin (the trailing `-`). Stdin must not be left open and empty, or Codex stops at `Reading additional input from stdin...`.
- The session ID is on the `session id:` line at the top of the log; rework needs it.
- `writable_roots` must include the build cache and temporary directories, or builds fail with read-only errors.
- `tokens used` is at the end of the log; after a resume the number may be the session total.

Rework (resuming the original session):

```bash
cd <worktree> && timeout 5400 codex exec resume <session-id> -m gpt-6.1-sol \
  -c model_reasoning_effort=high -c sandbox_mode="workspace-write" \
  -c 'sandbox_workspace_write.writable_roots=[...]' \
  -o <out>/r2-final.txt - < <rework.md> > <out>/r2-log.txt 2>&1
```

## 2. Codex Reviewer (codex-review)

```bash
cd <blind-copy> && codex-review -e xhigh -o <out>/gpt-X.txt "$(cat <review-prompt.txt>)"
```

- `codex-review` is a local wrapper (`~/.local/bin/codex-review`). It connects stdin to `/dev/null`, exits with code 3 if Codex has not started work within 90 seconds, exits with 124 on timeout, and prints the final answer when done.
- It must run inside a git repository. Treat any non-zero exit code as "not reviewed": 3 = never started, 124 = timed out, anything else = error (quota 429 and the like).
- The final answer starts on the second line after the last `tokens used` line of the output file; `scripts/merge-findings.py` extracts it that way.
- Use `-e xhigh` for security, concurrency, migrations, billing or large changes; `-e high` for ordinary changes.

## 3. Devin Implementer and Reviewer

```bash
cd <worktree> && timeout 3600 devin --config <cfg.json> --model gemini-4-argon-high \
  --sandbox --respect-workspace-trust false \
  [-r <session-name>] \
  --export <out>/conversation.md --prompt-file <prompt.md> -p < /dev/null > <out>/final.txt 2>&1
```

- **`--sandbox` is required.** Under `-p`, `--permission-mode accept-edits` rejects every command that is not read-only, and `dangerous` is blocked by Claude Code's safety classifier. `--sandbox` needs bubblewrap and socat.
- The sandbox can write only to the working directory. Network access is not restricted, so kubeconfig, `~/.kube` and SSH private keys must be in the deny list.
- **Implementer config:** in `permissions.allow`, grant `Edit(<worktree>/**)`, `Write(<worktree>/**)` and Write on the build cache directories by path. Never use bare `edit`/`write` without a path, which allows any path.
- **Read-only reviewer config:** grant no workspace Edit/Write at all; see `scripts/devin-readonly.example.json`.
- **Verifier config:** grant Edit/Write only on that verifier's own blind copy, its TMPDIR and the build caches; deny the other copies and the review materials except the findings file. See `scripts/devin-verifier.example.json`. Recommended models: `swe-2-max` (free) or `glm-5-3-high`.
- **TMPDIR must not sit under a read-denied directory.** A verifier whose TMPDIR was under a denied path could not even list it and fell back to a temporary directory inside the repository.
- Disable Devin's built-in `web_search` and `run_subagent` (put them in deny).
- If the config denies reading the directory the prompt file lives in, files the prompt refers to cannot be read; inline their content into `--prompt-file`.
- In `-p` mode stdout stays empty until the end; to check progress, look at `~/.local/share/devin/cli/logs/devin_<time>_<pid>.log`.
- Resuming: the session name is in the `"session_id"` field of the `--export` file (for example `luminous-sodalite`); pass it with `-r <session-name>`.
- Token usage is in the export and is cumulative for the session (per step: `prompt_tokens`, `completion_tokens`, `cached_tokens`).

`devin models` is the authoritative model list; models marked `Free` do not consume credits.

## 4. Background Execution and Waiting

- Start every implementer, reviewer and verifier with the Bash tool's `run_in_background`, and wait only for completion notices.
- When starting several jobs at once, write a bash script with one subshell per job; each appends `exit-code start end` to a shared timing file when it finishes, and the script ends with `wait`.
- Background Bash jobs are limited to 10 minutes. Run longer batches detached (`setsid nohup <script> &`) and follow their timing file with the Monitor tool.
- Do not find processes to wait on with `pgrep -f`: it matches the watching command itself, or same-named processes from other sessions.
- When the user asks about progress, `tail` the output file or the Devin log to confirm work is advancing before answering.

## 5. Environment Isolation

- One git worktree and one test database per implementer.
- Blind review copies are independent clones (`scripts/make-blind-copy.sh`), not worktrees: a worktree shares refs with the source repository, so `git branch -a` reveals the implementer's branch name.
- Put large temporary files on a data disk (`GOTMPDIR`, `TMPDIR`, pytest `--basetemp`), never on a RAM-backed `/tmp`.
- Run the full gate only when no agent is running. Check `free -m` and `df -h /tmp` before starting a large job.

## 6. Known Pitfalls

- **zsh does not split variables on spaces:** `set -- $p` and `for x in $list` do not split in zsh. Write multi-argument batch commands as bash scripts or bash functions and pass arguments explicitly.
- **`sleep N; cmd` chains are blocked:** to wait, use a background job's completion notice.
- **Raw Codex review output is large** (hundreds of KB of tool-call logs): extract only the final answer before merging.
- **Test order dependence:** earlier tests in a package can warm caches so that later tests "pass in the full package, fail alone". Run the tester's tests individually or with `-shuffle=on`.
- **Timing tests under high load:** at load 8-13 they fail intermittently and pass when rerun alone; record which ones, and do not take them as evidence of an implementation defect.
- **Devin `--sandbox` leaves socat processes behind:** every run starts a pair of `socat` proxies (listening on `claude-http-*.sock` / `claude-socks-*.sock` under TMPDIR, or `/tmp` when TMPDIR is unset) that are reparented to init and never exit; one benchmark batch left 80 of them, and they keep the blind copies busy. After a batch, list them with `ps -eo pid=,args= | awk '$2=="/usr/bin/socat" && /<your TMPDIR>\//'` and kill those exact PIDs; do not use a broad `pkill socat`, which also kills proxies of sessions still running.
- **Content moderation:** avoid words like "adversarial", "bypass" or "leak" in review prompts; Codex may refuse. If needed, split the prompt into parts and run them serially.
