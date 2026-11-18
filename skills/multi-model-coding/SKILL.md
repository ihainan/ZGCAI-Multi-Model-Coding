---
name: multi-model-coding
description: Orchestrates several models on a medium-to-large coding task using the "controller + Codex implementer + independent tester + GPT/Gemini cross-family blind review + measured verification" paradigm - drafts and reviews the spec, writes the task brief, dispatches the implementer and the tester, builds anonymous review copies, runs the dual review, merges findings for verifiers to reproduce, and resumes the implementer's session for rework. Use when a coding task has a written spec and automated acceptance tests and is large enough to delegate (hundreds to thousands of changed lines), or when the user asks to have Codex, Devin or other models implement or review code under the controller's supervision.
---

# Multi-Model Coding

The current session acts as the controller. The rules below come from two experiments (2026-11-12) and from running work packages of one Go project from 2026-11-13 on; data, reasoning and their limits are in [reference/paradigm.md](reference/paradigm.md).

The skill is project-neutral. Everything that depends on a project or a machine (how the full test suite is run and where, where heavy or timing-sensitive runs execute, temporary and cache directories, test databases, read-deny lists, known flaky tests) lives in the project's **environment profile** (template 7 in [reference/templates.md](reference/templates.md)). Read the profile before step 1; when a project has none, write one with the user first.

## Scope

- Use for: tasks with a clear spec, automated acceptance, and hundreds to thousands of changed lines per round.
- Do not use for: exploratory prototypes, documentation-only work, small changes, or work that needs frequent confirmation from the user. The controller does those directly.

## Roles

| Role | Default | Notes |
|---|---|---|
| Controller | Current session | Writes or commissions the spec, rules on every question and failure, writes the task brief, runs acceptance, merges findings, rules on verification results, merges code |
| Drafter | A subagent of the controller's choosing | Optional; writes the spec from the controller's scope decisions and revises it to the rulings |
| Implementer | Codex (gpt-6.1-sol high, workspace-write) | Switch to an Opus subagent when the spec leaves much to the implementer's judgment |
| Tester | An agent other than the implementer | Writes black-box tests from the same spec; measures independently of the product's own reported numbers; never reads the implementer's directory |
| Reviewers | One GPT review (`scripts/codex-review`) and one Gemini review (Devin, read-only config) | Read-only and blind; every finding gives file:line, trigger, numbers and consequence |
| Verifier | Devin `swe-2-max` or `glm-5-3-high`, one per candidate (config: `scripts/devin-verifier.example.json`) | Reproduces each finding group and rules confirmed, partly confirmed, not confirmed or undetermined; leaves the working tree clean. Check its "which round introduced it" calls and every "confirmed" without a spec citation |

## Standard Workflow

Copy this checklist and work through it:

```
- [ ] 1. Spec: write requirements as verifiable items; state hard limits and the unit of measurement as numbers. Leave cross-cutting details to the project's default-conventions file (template 6). List the existing tests the package may change; when the package bumps a stored format, schema or config version, include every test that runs an older release against the new format. For exhaustive tasks, apply "Exhaustive Tasks" first.
- [ ] 2. Size check: at most about 30 acceptance items, first implementation round about 1-1.5 hours. If the draft grows past that, split it into separate packages now; do not keep one spec and stage the implementation instead.
- [ ] 3. Spec review: GPT and Gemini blind-review the draft; the controller checks every finding against the code and rules on it; then one targeted recheck of the last version's changes (one reviewer is enough).
- [ ] 4. Spec pre-read: the tester lists only what it cannot write a test for (template 5). The controller rules on every question and commits the rulings. Only then start step 7.
- [ ] 5. Fixtures and test data: the controller writes a checker that asserts the expected numbers; an agent generates the data files; the controller commits them once the checker passes.
- [ ] 6. Task brief: template 1; all implementers share one brief; its allowed-paths list is also the input of scripts/check-scope.sh.
- [ ] 7. Implementation and tests: one git worktree and one test database per implementer; the tester works in its own worktree at the same time. Wait for each job's own exit, not by searching processes.
- [ ] 8. Scope check: scripts/check-scope.sh on every delivery; rule on each out-of-scope file before reading the rest of the diff.
- [ ] 9. Controller acceptance: merge the tester's tests; run the acceptance commands where the profile says acceptance runs; run the tester's tests one at a time or in random order; repeat tests prone to nondeterminism many times; run write-then-read sequences against the real server and walk through the UI (hard rule 11). Rule on every failure: spec, implementation or test.
- [ ] 10. Blind copies: scripts/make-blind-copy.sh builds an independent clone per candidate (no other branches, neutral commit messages).
- [ ] 11. Dual review: scripts/run-dual-review.sh runs GPT and Gemini on each copy in parallel with the same prompt; when one reviewer failed, rerun only that one with REVIEWERS=gpt or REVIEWERS=gem.
- [ ] 12. Merge: scripts/merge-findings.py writes both reviews as "Review X" and "Review Y" in random order, stores the mapping separately, and refuses to merge a review whose run did not succeed.
- [ ] 13. Verification: one verifier per candidate (template 3); spot-check the verdicts; record each reviewer's precision and unique findings.
- [ ] 14. Rework: resume the implementer's original session; attach the full verification report, a cross-candidate checklist and one unified measurement ruling (template 4).
- [ ] 15. Fix check: when the rework stayed within the confirmed issues, one reviewer checks them and the rework diff; when it changed more (new logic, many files), repeat steps 10-13. If P1 issues remain after two rounds, stop and decide whether the problem lies in the spec or in the implementation.
- [ ] 16. Merge and full acceptance: merge current main, run the project's full acceptance suite as the profile prescribes, rule on every failure (known failures listed in the profile are marked, not ignored), then close out per the project's own rules.
```

## Hard Rules

1. **Implementers' self-reports and self-checks are not acceptance evidence.** In the experiments all three implementers reported "all items closed"; verification found limit violations in all three.
2. **Spec reviews and code reviews use two model families.** In the experiments neither reviewer alone found everything the pair found, and GPT missed a nondeterminism bug in GPT-written code. Exceptions, and only these: the targeted recheck of a spec's last revision, and the fix check of a rework that stayed within the confirmed issues, may use one reviewer. In the experiments a broad round-2 rework introduced new problems (paradigm.md 2.4), so a broad rework gets the full dual review. A review whose tool exited non-zero did not happen: rerun it, never count it.
3. **Reproduce findings before rework.** Findings with inflated numbers or constructions that do not reproduce are common, and a reviewer has marked an unfixed issue as fixed.
4. **Run the tester's tests individually or in random order** (for example Go `-shuffle=on`, pytest `-p random_order`). A defect that "always fails alone, passes in the full package run" was missed by controller acceptance, both reviews and the verifier.
5. **Build blind copies as independent clones, never as worktrees.** A worktree shares refs with the source repository: `git branch -a` reveals the implementer's branch name, and when the source repository's main moves, `git diff main HEAD` in the copy changes scope.
6. **Restate the read-deny list and the rules in full in every task message,** including resumed sessions. Do not rely on the other agent remembering earlier constraints.
7. **Wait on the exact job you started** (its completion notice, its exit-code file or its PID). Never find processes with `pgrep -f`, which matches the watcher itself or other sessions' processes.
8. **Do not start the implementer before the spec pre-read is ruled.** A Codex run cannot take messages; every ruling made after it starts costs a full rework round.
9. **Keep work packages small** (workflow step 2). A 70-item package took four hours of drafting and three full review rounds; a 37-item package went through six spec versions.
10. **Accept on the whole repository's tests, after merging current main.** A package's own tests and its tester's tests both missed a start-order regression that only older packages' tests caught.
11. **Acceptance includes the real server, not only in-process test clients.** In-process clients (FastAPI/Starlette `TestClient`, Go handlers called through `httptest.ResponseRecorder`) wait for request teardown before returning, so they hide defects where work such as a database commit runs after the response is sent. In one acceptance, about 80% of "log in, then immediately call `/api/me`" requests got 401 on a real server while 594 tests, two reviewers and the implementer's own browser check had all passed.
12. **Rulings cite the rule they rest on.** When a ruling touches behavior an earlier package defined, cite that rule; a ruling that contradicted one sent the implementer into a special case in a shared framework.

## Exhaustive Tasks

Requirements such as "every loop is metered", "every endpoint is authenticated" or "every error path releases its resources" do not converge through review and rework rounds: each extra round uncovers another batch of missed paths. Handle them in this order:

1. **Mechanism before patching:** turn the requirement into a structural constraint (for example, every loop goes through one metering primitive), then add a static check that rejects exceptions.
2. **Independent measurement:** the tester's measurements must not reuse numbers the product reports about itself.
3. **Inventory before implementation:** one agent produces the complete inventory, both reviewers fill gaps, the controller approves it, then implementers receive their share.
4. **Stop condition:** if P1 issues remain after two fix-check rounds, stop and decide; do not start a third patching round.

## Choosing Implementers and Reviewers

| Situation | Implementer | Review |
|---|---|---|
| Medium change with a clear spec | Codex high | GPT xhigh + Gemini, verify, then rework |
| Implementer must make many judgment calls | Opus subagent | GPT xhigh + Gemini; run the tester's tests individually |
| Concurrency, security, billing, migrations | Codex high or Opus | Dual review plus repeated and random-order test runs |
| Exhaustive requirement | Mechanism and inventory first (see above) | Dual review of the inventory as well |
| Small fix (one function, one ruling) | Resume the original implementer session | One GPT fix check (hard rule 2 exception) |
| Comparing approaches | Several implementers in parallel | Dual review + verification; about 3x the tokens of one implementer |

These defaults rest on few samples (paradigm.md sections 2 and 12: one task for the reviewer comparison, one sample per model for the substitution benchmark, scored by the controller). Treat them as the current best guess, not a ranking; revisit them when a project's own review-quality records disagree.

## Reference Files

- [reference/templates.md](reference/templates.md): task brief, review prompt, verification brief, rework brief, spec pre-read brief, default-conventions checklist and environment-profile template.
- [reference/tooling.md](reference/tooling.md): Codex and Devin commands, permission configs and known pitfalls.
- [reference/paradigm.md](reference/paradigm.md): the full paradigm document with experiment data and per-package observations.
- `scripts/`: `codex-review` (read-only Codex review wrapper), `make-blind-copy.sh`, `run-dual-review.sh`, `merge-findings.py`, `check-scope.sh`; usage is in each script's header. `scripts/tests/run-tests.sh` tests them with fake tools. `scripts/devin-readonly.example.json` and `scripts/devin-verifier.example.json` are sample Devin configs for a read-only reviewer and for a verifier.
