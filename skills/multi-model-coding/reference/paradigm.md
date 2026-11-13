# Multi-Model Collaborative Development Paradigm

## Contents

1. Overview
2. Experimental Evidence
3. Roles
4. Standard Workflow
5. Exhaustive Tasks
6. Task Brief Structure
7. Review and Verification
8. Rework and Session Resumption
9. Gate and Environment Isolation
10. Selection Guidelines
11. Open Questions

## 1. Overview

**Conclusion**: Claude acts as controller and owns the spec, rulings, verification and acceptance. Implementation goes to Codex (gpt-6.1-sol high) by default. Every review round is done blind by **two model families, GPT and Gemini**, and findings are **verified by measurement** before rework. Rework resumes the implementer's original session. In two experiments this approach matched the quality of "Opus implements + GPT reviews" and was about 1.8x faster in the first implementation round. Two limitations apply. First, for exhaustive tasks such as "every loop must stay within the limit", review and rework rounds do not converge, so the check must first become a mechanism. Second, the tester's tests must run individually or in shuffled order, or defects that depend on test order are missed.

Project terms used in this document:

- **ZGCAI-Model-Gateway**: an in-house model gateway written in Go and developed under clean-room "rewrite from spec" rules (implementers and testers may not read the code of designated legacy systems).
- **The G118 task**: the gateway's tokenizer module may do at most 256 KiB (262,144 units) of work between two "has the request been cancelled?" checks. The spec listed 12 places that exceed this limit, and the task was to bring all of them within it. Correctness can be measured exactly, which makes the task suitable for comparing models.
- **P1 / P2 / P3**: severity of review findings. P1 is a defect that must be fixed, P2 a problem that should be fixed, P3 a suggested improvement.
- **Limit violation**: measured work between two cancellation checks exceeds 262,144.
- **codex-review**: a local wrapper script for read-only Codex (GPT) reviews with fixed input handling, timeout and exit codes.
- **Devin CLI**: Cognition's command-line coding agent, used here to drive the Gemini 4 Argon model.

Applies to: medium-to-large coding tasks with a clear spec and automated acceptance tests (hundreds to thousands of changed lines per round). Does not apply to exploratory prototypes, documentation-only work, or work that needs frequent confirmation from the user.

## 2. Experimental Evidence

### 2.1 Experiment Design

| Experiment | Task | Participants | Metrics |
|---|---|---|---|
| Experiment 1 | P1.6a review fixes, 5 rounds (rulings 12.9-12.13) | Devin (Gemini 4 Argon high) implements; Opus tests and controls; GPT does fix checks | Time per round, tokens, rework causes, findings per fix check |
| Experiment 2 | G118, two rounds | One shared task brief; an Opus subagent, Devin and Codex (gpt-6.1-sol high) implement in parallel; each round GPT xhigh and Gemini each blind-review all three; Opus verifiers reproduce every finding; all three resume their original sessions for rework | Implementation and rework time, acceptance results, review precision and recall, final residual issues |

### 2.2 First Implementation Round

| Implementer | Time | Tokens | Controller acceptance (5 acceptance commands) | Limit violations after verification |
|---|---|---|---|---|
| Codex gpt-6.1-sol high | 49 min 51 s | 286K | 1 failure: introduced nondeterminism (8 failures in 40 runs) | 3 paths, plus 1 case of continuing to parse after cancellation |
| Devin gemini-4-argon-high | 57 min 15 s | 19.84M input (86% cached), 182K output | All passed | 5 paths, plus 1 case of continuing to parse after cancellation |
| Opus subagent | 90 min 38 s | 182K | All passed (one tester test was later found to always fail when run alone; see 2.5) | 4 paths, plus 1 case of continuing to parse after cancellation |

All three passed every acceptance command and reported "all 12 rows closed"; verification found limit violations in all three. **Implementers' self-reports and self-checks are not acceptance evidence.**

### 2.3 Rework

All three resumed their original sessions at the same time. The rework brief attached the full verification report and a cross-candidate checklist of 11 issues of the same kind.

| Implementer | Resumption method | Rework time | Rework tokens | First-round time |
|---|---|---|---|---|
| Opus subagent | SendMessage | 32 min 08 s | 210K | 90 min 38 s |
| Devin | `devin -r` | 50 min 56 s | about 27.74M input (89% cached), 135K output | 57 min 15 s |
| Codex | `codex exec resume` | 56 min 39 s | 572K in the log (possibly the session total) | 49 min 51 s |

After rework all three passed every acceptance command, and Codex's nondeterminism was fixed. Whole-package tests with `-race` became slower: Opus 203→234 s, Devin 226→283 s, Codex 236→323 s (budget 240 s). The increase is instrumentation overhead in test builds; the performance gates on production builds all passed.

### 2.4 Final Residual Issues

The round-2 fix check also used the GPT and Gemini dual review, with findings reproduced by verifiers.

| Candidate | Pre-existing on main, outside the spec list | Introduced by the implementer and still unfixed | Newly introduced in round 2 |
|---|---|---|---|
| Codex implementation | 5 limit violations (max 2,162,688, about 8x the limit) | None | None |
| Devin implementation | 2 limit violations (max 1,277,954) | Inconsistent check counts when counting repeats | 2: continuing work after cancellation mid-sort; a short-field-name comparison shortcut exceeding the limit at 295,422 |
| Opus implementation | 3 limit violations (max 331,234) | A tester test always fails when run alone; a small amount of work continues after cancellation | 1, within the limit |

Key points:

1. **Codex's final result was the cleanest**: everything left over was pre-existing on main and outside the task list; it introduced no problems of its own.
2. Devin introduced 2 new problems during rework. The test-order-dependent defect Opus introduced in round 1 took two review rounds to surface.
3. All three still contained pre-existing gaps of the same kind on main; the internal table lookup in NFC normalization is one example. These gaps appeared in neither round-1 review, nor the verification, nor the cross-candidate checklist; they surfaced only in round 2. **For exhaustive tasks such as "every loop must stay within the limit", each extra review-and-rework round uncovers another batch; adding rounds does not converge.**

### 2.5 Review Quality

| Reviewer | Time per review | Tokens per review | Finding groups over two rounds | Confirmed | Partly confirmed | Not confirmed |
|---|---|---|---|---|---|---|
| GPT xhigh (codex-review) | 10-25 min | 150K-190K | 26 | 25 | 1 | 0 |
| Gemini (Devin read-only config) | 19-50 min | 3.93M-5.27M input (80%-93% cached), 80K-170K output | 30 | 25 | 5 | 0 |

| Round | Candidate | Limit violations found by both | Found by GPT only | Found by Gemini only |
|---|---|---|---|---|
| Round 1 | Devin implementation | 0 | 3 (including the most severe, 425,984) | 2 |
| Round 1 | Codex implementation | 1 | 0 | 3 (including the nondeterminism) |
| Round 1 | Opus implementation | 1 | 0 | 3 (including the most severe, 376,624) |
| Round 2 | Devin implementation | 2 | 1 | 0 |
| Round 2 | Codex implementation | 3 | 0 | 2 |
| Round 2 | Opus implementation | 0 | 1 | 2 |

Key points:

1. **The two reviewers' findings overlap very little.** Across both rounds there were 24 limit violations: 7 found by both, 5 by GPT only and 12 by Gemini only. GPT alone finds 50%, Gemini alone 79%; only the two together find all of them.
2. **Same-family blind spot**: GPT missed the nondeterminism Codex introduced in round 1; Gemini found it and identified the correct root cause.
3. GPT's severity judgments and numbers are accurate, and it is about twice as fast. Gemini has higher recall, but its numbers are often inflated or its constructions do not reproduce as written, and once it marked an unfixed issue as fixed, so its findings must be verified.
4. The defect where an Opus tester test "always fails alone, passes in the full package run" was missed by controller acceptance, both round-1 reviews and the verifier; GPT found it in round 2 by running that test on its own.

### 2.6 Session Resumption (Experiment 1)

| Round | Method | Size | Time |
|---|---|---|---|
| Round 3 | New session | Remove one block of logic, change one self-check, update docs | 17 min 28 s |
| Round 5 | Resumed the round-4 session (`-r`) | Similar to round 3 | 7 min 39 s |

For small rework, resuming is about 2.3x faster. In experiment 2 the rework scope was close to the first round's workload; Codex and Devin took about as long as their first rounds after resuming, and only Opus dropped to 35% of its first-round time.

## 3. Roles

| Role | Assigned to | Responsibilities | Prohibited |
|---|---|---|---|
| Controller | Claude (Opus, main session) | Writes the spec and rulings; writes the task brief; runs the gate; merges review findings; rules on verification results; decides rework scope; merges code | Running the full gate while other agents are running |
| Implementer | Codex by default (gpt-6.1-sol high, workspace-write); an Opus subagent when the spec is vague and the implementer must make its own judgments; Devin (Gemini) as a third choice | Changes code per the task brief, adds self-checks, writes delivery notes | Reading denied directories; spawning subagents; committing to git |
| Tester | An agent other than the implementer (Opus subagent) | Writes black-box tests from the same spec; measures without relying on numbers the product reports about itself | Reading the implementer's directory |
| Reviewers | One GPT xhigh and one Gemini review | Read-only blind review giving file:line, trigger, numbers and consequence | Changing code; knowing the implementer's identity |
| Verifiers | Opus subagents, one per candidate, in parallel | Reproduce merged findings group by group and rule confirmed, partly confirmed, not confirmed or undetermined | Leaving changes behind; `git status` must be empty when done |

Rationale:

- **Codex as implementer**: fastest first round, fewest tokens, and no self-introduced problems left after rework. Its first-round self-review is less thorough than Opus's, so it must be paired with a Gemini review.
- **Opus subagent as implementer**: slowest first round but fastest rework, and it proactively makes related fixes beyond the task and runs performance comparisons. The downside is that the defects it introduces can be subtle (test-order dependence).
- **Devin (Gemini) as implementer**: mid-range speed, but it introduced new problems during rework; headless mode gives no progress output and edit permissions must be granted per directory, so it has the highest operating cost.

## 4. Standard Workflow

| Stage | Method | Output | Measured time (medium task) |
|---|---|---|---|
| 1. Spec and rulings | Write the work as verifiable items with hard limits, units of measurement and exceptions; handle exhaustive tasks per section 5 first | Spec items, ruling numbers | — |
| 2. Task brief | Write it from the section 6 structure; all implementers share one brief | Task brief file | 10 min |
| 3. Implementation | Implementers work in separate worktrees; run several in parallel when comparing approaches | Change + delivery notes | 50-90 min |
| 4. Controller acceptance | Rerun the acceptance commands on an idle machine; run the tester's tests one by one or with `-shuffle=on`; add `-count=40` runs for tests prone to nondeterminism | Acceptance record | 10-20 min |
| 5. Cross-family dual review | Copy each candidate into an anonymous read-only copy with neutral commit messages; GPT and Gemini review in parallel with the same prompt | Two reviews | 10-50 min |
| 6. Verification | Merge each candidate's two reviews into one file without sources; verifiers reproduce them group by group | Verification report | 7-12 min |
| 7. Rework | Resume the implementer's original session; attach the verification report and the cross-candidate checklist; the controller rules on one unified unit of measurement | Fixes + regression self-checks | 30-60 min |
| 8. Fix check | Dual review and verification again; if P1 issues remain, the controller decides whether the problem is in the implementation or the spec, and spec problems go back to stage 1 | Fix-check record | 20-45 min |
| 9. Merge and gate | Merge into the work-package branch and run the full gate while no agent is running | Gate record, STATUS update | 30-45 min |

In experiment 2, end to end from the start of implementation to the end of round-2 verification took about 4 h 45 min (three implementers in parallel). Codex's implementation and rework took about 1.8 h of that; the rest was acceptance, review and verification.

## 5. Exhaustive Tasks

In tasks such as "every loop must be metered", "every endpoint must be authenticated" or "every error path must release its resources", defects are spread across the whole codebase and the spec list is hard to make complete. In both rounds of experiment 2, each round uncovered a new batch of missed paths, most of them pre-existing on main and absent from the list. Handle such tasks in this order:

1. **Mechanism before patching**: turn the requirement into a structural constraint in the code, for example every loop must go through one metering primitive, and use static analysis or a lint rule to reject loops that bypass it. Patching only the listed items leaves another round after every round.
2. **Independent measurement**: the tester's measurements must not reuse numbers the product reports. In experiment 2 all three implementations' self-checks "passed" while the real work exceeded the limit by 2-8x, because the self-checks and the product shared the same number.
3. **Inventory before implementation**: before any changes, one agent produces the complete inventory (for example "every loop in the package and how it is metered"), both reviewers fill gaps, and the controller approves it before it is split among implementers.
4. **Stop condition**: if P1 issues remain after two fix-check rounds, stop and have the controller decide whether the problem lies in the spec or the implementation; do not start a third patching round.

## 6. Task Brief Structure

A task brief has the following fixed structure; each missing part causes rework at a later stage:

1. **Identity and scope**: "You are the implementer for X; this round covers only Y"; the working directory; the packages involved.
2. **Read first**: list the exact spec sections and related source files, not "read the relevant docs".
3. **Requirements**: numbered, each verifiable; hard limits and units of measurement written as numbers (for example, "copying n bytes counts n, in bytes, not elements"). When the unit was left unclear, the three implementers each chose a different one, and review and verification could not compare them.
4. **Invariants**: which behavior, results and performance must not change; which tests belong to the tester and must not be modified.
5. **Self-check requirements**: the naming suffix for new tests; they must fail before the change; measured numbers before and after; counting at the actual loop sites, not reusing numbers the product reports.
6. **Acceptance commands**: listed one by one and run in order before delivery; repeated runs for tests prone to nondeterminism; individual or shuffled runs for the tester's tests.
7. **Delivery notes**: which file and section in the repository, and which columns.
8. **Rules**: the clean-room read-deny list (restated in full in every task message), no subagents, no network, no git commits, the language for comments.

Fill-in templates are in [templates.md](templates.md).

## 7. Review and Verification

### 7.1 Blind Review

- Copy each candidate into anonymous copies `rv-A`, `rv-B`, `rv-C` on a detached HEAD, with neutral commit messages. Build them as independent clones, not worktrees (see `scripts/make-blind-copy.sh`).
- The review prompt embeds the full task brief and requires every finding to give P1/P2/P3, file:line, trigger, measured or estimated numbers, and consequence.
- Reviewers must be read-only: Codex via `codex-review`; Devin with a config that grants no workspace Edit/Write.
- GPT and Gemini run in parallel and each reviews every candidate. Fix-check rounds use the dual review as well.

### 7.2 Verification

- Each candidate's two reviews are concatenated into one file as "Review X" and "Review Y" in random order, with the mapping stored separately.
- Verifiers first merge findings with the same root cause, then reproduce each group. The recommended method is to temporarily instrument the cited loop and take the maximum difference between two checks.
- There are four verdicts: confirmed, partly confirmed, not confirmed, undetermined; verdicts reached by reading code alone must be marked. Fix-check rounds also require stating whether each issue was "introduced in this round", "left over from the previous round" or "pre-existing on main".
- The working directory must be clean when verification ends.

### 7.3 Review Quality Tracking

Every time, record each reviewer's precision (confirmed plus partly confirmed ÷ reported) and number of unique findings. Across both rounds of experiment 2, GPT alone would have missed half of the limit violations and Gemini alone about one fifth, and GPT's unique findings were often the most severe ones (425,984 in round 1, the test-order dependence in round 2). Do not switch to a single reviewer.

## 8. Rework and Session Resumption

- Rework resumes the original session: Codex with `codex exec resume <session ID> -`, Devin with `devin -r <session name>`, an Opus subagent with SendMessage. For small rework, resuming is about 2.3x faster; when the rework scope approaches the first round's, resuming and starting fresh take about the same time.
- The rework brief attaches the full verification report; when the implementer's permission config denies reading the directory the brief lives in, inline the report into the prompt.
- **Cross-candidate checklist**: issues confirmed by measurement on any candidate are collected into a checklist sent to every implementer, each item requiring "fix it if present, otherwise give the code location".
- The controller rules on one unified unit of measurement in the rework brief, so implementers cannot claim "within the limit" by their own unit.

## 9. Gate and Environment Isolation

- Run the full gate only when no implementer, reviewer or verifier is running. In the experiments, 5 timing tests failed at machine load 8-13 and all passed when rerun alone.
- Each implementer uses its own git worktree and its own test database.
- Put large temporary files on a data disk: point `GOTMPDIR` and `TMPDIR` at a data-disk cache directory, and allow the same directories in the Codex sandbox's `writable_roots`.
- Devin permissions: grant edits only by path, to this round's worktree; deny reading other worktrees, spec sources and prototype directories. In headless mode stdout shows no progress; check the logs under `~/.local/share/devin/cli/logs/` to see whether it is advancing.
- Always run Codex reviews in the background through `codex-review` and wait only for completion notices; treat any non-zero exit code as "not reviewed".

## 10. Selection Guidelines

| Scenario | Implementer | Review | Notes |
|---|---|---|---|
| Medium change with a clear spec | Codex high | GPT xhigh + Gemini, verify, then rework | Default combination |
| Implementer must make many judgment calls | Opus subagent | GPT xhigh + Gemini | First round about 1.8x slower, rework faster; run the tester's tests individually during acceptance |
| Concurrency, security, billing, migrations | Codex high or Opus | GPT xhigh + Gemini, plus `-count` and `-shuffle=on` runs | Only the cross-family review caught the nondeterminism |
| Exhaustive requirement (every loop, every endpoint) | Mechanism and inventory first, per section 5 | Dual review of the inventory as well | Direct patching does not converge |
| Small fix (one function, one ruling) | Resume the original implementer session | One GPT check | Resuming is about 2.3x faster |
| Comparing approaches, picking the best implementation | Several in parallel | Dual review + verification | About 3x the tokens of one implementer; use only when approaches differ widely |

## 11. Open Questions

- When the rework scope approaches the first round's, whether a fresh session with a consolidated brief is faster and better than resuming.
- How well section 5's "mechanism before patching" works on G118 in practice (a possible next step is to redo G118 that way).
- Whether the cross-family dual review is as complementary on tasks that are not in Go or not spec-driven.
- Why Gemini review time varies so widely (19-50 minutes); not yet investigated.
