---
name: multi-model-coding
description: Orchestrates several models on a medium-to-large coding task using the "controller + Codex implementer + GPT/Gemini cross-family blind review + measured verification" paradigm - writes the task brief, dispatches implementers, builds anonymous review copies, runs the dual review, merges findings for verifiers to reproduce, resumes the implementer's session for rework, and runs the full gate on an idle machine. Use when a coding task has a written spec and automated acceptance tests and is large enough to delegate (hundreds to thousands of changed lines), or when the user asks to have Codex, Devin or other models implement or review code under the controller's supervision.
---

# Multi-Model Coding

The current session acts as the controller. The rules below come from two experiments run on 2026-11-12 and from running work package P1.6b on 2026-11-13; data and reasoning are in [reference/paradigm.md](reference/paradigm.md).

## Scope

- Use for: tasks with a clear spec, automated acceptance, and hundreds to thousands of changed lines per round.
- Do not use for: exploratory prototypes, documentation-only work, or work that needs frequent confirmation from the user. The controller does those directly.

## Roles

| Role | Default | Notes |
|---|---|---|
| Controller | Current session | Writes the spec and rulings, writes the task brief, runs acceptance, merges findings, rules on verification results, merges code, runs the gate |
| Implementer | Codex (gpt-6.1-sol high, workspace-write) | Switch to an Opus subagent when the spec leaves much to the implementer's judgment |
| Tester | An agent other than the implementer | Writes black-box tests from the same spec; measures independently of the product's own reported numbers; never reads the implementer's directory |
| Reviewers | One GPT xhigh review (`codex-review`) and one Gemini review (Devin read-only config) | Read-only and blind; every finding gives file:line, trigger, numbers and consequence |
| Verifier | Devin `swe-2-max` (free) or `glm-5-3-high`, one per candidate, in parallel (config: `scripts/devin-verifier.example.json`) | Reproduces each finding group and rules confirmed, partly confirmed, not confirmed or undetermined; leaves the working tree clean. Both scored within 1.5 of 18 against the controller's own verification at a fraction of the cost; check their "which round introduced it" calls, the weakest part for every model tested |

## Standard Workflow

Copy this checklist and work through it:

```
- [ ] 1. Spec: write requirements as verifiable items; state hard limits and the unit of measurement as numbers. Leave cross-cutting details (JSON key names, pagination, time formats, alert attributes, error wrapping) to the project's default-conventions file instead of deciding them per package. For exhaustive tasks, apply "Exhaustive Tasks" first.
- [ ] 2. Size check: one work package holds at most about 30 acceptance items, and the implementer should finish its first round in 1-1.5 hours. Split anything larger before review.
- [ ] 3. Spec pre-read: the tester reads the reviewed spec and only lists what it cannot write a test for ("Spec Pre-read Brief" in reference/templates.md, about 30 minutes). The controller rules on every question and commits the rulings. Only then start steps 5 and 6.
- [ ] 4. Fixtures and test data: the controller writes a checker that asserts the expected numbers; Codex generates the data files; the controller commits them once the checker passes.
- [ ] 5. Task brief: use the "Task Brief" template in reference/templates.md; all implementers share one brief.
- [ ] 6. Implementation and tests: one git worktree and one test database per implementer; the tester works in its own worktree at the same time. Run in the background and wait only for completion notices.
- [ ] 7. Controller acceptance: rerun the acceptance commands on an idle machine; run the tester's tests one at a time or with -shuffle=on; run tests prone to nondeterminism with -count=40; run write-then-read sequences against the real server and walk through the UI (hard rule 12).
- [ ] 8. Blind copies: scripts/make-blind-copy.sh builds an independent clone per candidate (no other branches, neutral commit messages).
- [ ] 9. Dual review: scripts/run-dual-review.sh runs GPT and Gemini on each copy in parallel with the same prompt.
- [ ] 10. Merge: scripts/merge-findings.py writes both reviews as "Review X" and "Review Y" in random order and stores the mapping separately.
- [ ] 11. Verification: dispatch one verifier per candidate using the "Verification Brief" template; spot-check the verdicts; record each reviewer's precision and unique findings.
- [ ] 12. Rework: resume the implementer's original session; attach the full verification report, a cross-candidate checklist and one unified measurement ruling.
- [ ] 13. Fix check: repeat steps 8-11. If P1 issues remain after two rounds, stop and decide whether the problem lies in the spec or in the implementation.
- [ ] 14. Merge and gate: merge into the work-package branch; run the full gate while no other agent is running; update the project status file.
```

## Hard Rules

1. **Implementers' self-reports and self-checks are not acceptance evidence.** In the experiments all three implementers reported "all items closed"; verification found limit violations in all three.
2. **Every review round uses two model families; never drop to a single reviewer.** Of 24 limit violations over two rounds, GPT alone found 50% and Gemini alone 79%. GPT missed a nondeterminism bug in GPT-written code.
3. **Reproduce findings before rework.** Gemini has higher recall, but its numbers are often inflated, some of its constructions do not reproduce, and once it marked an unfixed issue as fixed.
4. **Run the tester's tests individually or shuffled.** A defect that "always fails alone, passes in the full package run" was missed by controller acceptance, both reviews and the verifier.
5. **Run the full gate only when no other agent is running.** At load 8-13, timing-sensitive tests fail intermittently.
6. **Build blind copies as independent clones, never as worktrees.** A worktree shares refs with the source repository: `git branch -a` reveals the implementer's branch name, and when the source repository's main moves, `git diff main HEAD` in the copy changes scope.
7. **Restate the read-deny list and the rules in full in every task message,** including resumed sessions. Do not rely on the other agent remembering earlier constraints.
8. **Wait for background work only through completion notices.** Do not find processes with `pgrep -f`; treat a review with a non-zero exit code as not done.
9. **Do not start the implementer before the spec pre-read is ruled.** A Codex run cannot take messages; every ruling made after it starts costs a full rework round. In work package P1.6b the tester raised 18 questions after the implementer had started (paradigm.md section 13).
10. **Keep work packages small.** About 30 acceptance items per package at most; a 70-item package took four hours of drafting and three full review rounds, and its first implementation round ran for hours.
11. **Accept on the whole repository's tests, after merging current main.** A package's own tests and its tester's tests both missed a start-order regression that only older binary tests caught (paradigm.md section 13.5).
12. **Acceptance includes the real server, not only in-process test clients.** In-process clients (FastAPI/Starlette `TestClient`, Go handlers called through `httptest.ResponseRecorder`) wait for request teardown before returning, so they hide defects where work such as the database commit runs after the response is sent. In the ZGCAI-Blog P1.2a acceptance (2026-11-15), about 80% of "log in, then immediately call `/api/me`" requests got 401 on a real uvicorn server, while 594 tests, two reviewers and the implementer's own browser check had all passed. Every controller acceptance runs write-then-immediately-read sequences against the real server with an independent HTTP client, plus a browser walk-through.

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
| Concurrency, security, billing, migrations | Codex high or Opus | Dual review plus `-count` and `-shuffle=on` runs |
| Exhaustive requirement | Mechanism and inventory first (see above) | Dual review of the inventory as well |
| Small fix (one function, one ruling) | Resume the original implementer session | One GPT fix check |
| Comparing approaches | Several implementers in parallel | Dual review + verification; about 3x the tokens of one implementer |

Model substitution data (2026-11-13, one sample per model): see paradigm.md section 12. In short: verifiers can move to SWE-2 or GLM; no cheap Devin model replaces the Gemini reviewer (only Carbon and Hydrogen match Argon, at over $4 per review); Kimi, Sonnet and DeepSeek match GPT on a single controller decision, but no model has been tested on a full controller session, so the controller stays the current session. Do not use Gemini models as controller: both recommended abandoning the candidate that ended up best.

## Reference Files

- [reference/templates.md](reference/templates.md): task brief, review prompt, verification brief, rework brief and spec pre-read brief templates, plus a checklist for the project's default-conventions file.
- [reference/tooling.md](reference/tooling.md): Codex, Devin and codex-review commands, permission configs and known pitfalls.
- [reference/paradigm.md](reference/paradigm.md): the full paradigm document with experiment data.
- `scripts/make-blind-copy.sh`, `scripts/run-dual-review.sh`, `scripts/merge-findings.py`: run them directly; usage is in each script's header. `scripts/devin-readonly.example.json` is a sample Devin config for a read-only reviewer; `scripts/devin-verifier.example.json` is one for a verifier that may instrument its own copy.
