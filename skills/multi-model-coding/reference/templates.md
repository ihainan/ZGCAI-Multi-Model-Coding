# Templates

## Contents

1. Task brief (sent to implementers)
2. Review prompt (sent to the GPT and Gemini reviewers)
3. Verification brief (sent to verifiers)
4. Rework brief (sent into the implementer's original session)
5. Spec pre-read brief (sent to the tester before implementation starts)
6. Default-conventions checklist (one file per project)
7. Environment profile (one file per project)

Braces mark placeholders. Templates 1-4 are the prompts actually used, and shown to work, in the 2026-11-12 experiments; templates 5 and 6 were added after work package P1.6b (2026-11-13) and have been used on later packages; template 7 was added on 2026-11-18. Project details are replaced by placeholders; fill the resource and environment placeholders from the project's environment profile. Write the filled-in prompt in whatever language the project works in.

---

## 1. Task Brief

```markdown
# {work package}: {one-line task}

You are the implementer for {repository}. This round covers only: {scope}. Working directory: `{WT}`. Packages involved: `{package paths}`.

## Read First

1. `CLAUDE.md` (the repository's development rules; follow all of them).
2. `{spec file}`, section {section number}; this task is governed by **{clause number}**.
3. `{existing implementation notes}`, section {section number}, and `{related source files}`.

## Requirements

1. {Verifiable item}. Hard limit: {number}. Unit of measurement: {for example, "hashing n bytes counts n; copying n bytes counts n (bytes, not elements); every comparison, swap, probe and loop iteration counts 1"}.
2. ...

## Invariants

- {Behavior and results that must not change}.
- The tester's tests `{file pattern}` must not be modified and must still pass.
- {Performance checks from the environment profile, if any} must still pass.
- Existing tests may be changed only as the spec's allowed-changes list says.

## Self-Check Requirements

- New test names end in `_{suffix}` and must fail before the change; the delivery notes give the measured numbers before and after the change.
- Count at the actual loop sites; do not reuse numbers the product reports about itself.

## Acceptance Commands

Run these in order and confirm they pass before delivery:

- `{format check}`
- `{static analysis}`
- `{unit tests}`
- `{tests with the race detector or observability tags}`
- `{tests prone to nondeterminism}`, repeated `{N}` times
- `{tester's tests}` in random order (or each one on its own)

## Delivery

Append a table to section "{section name}" of `{delivery notes file}` with the columns: {column names}. Summarize in a few sentences in your final reply and state whether anything is unfinished.

## Rules (breaking any one of them voids this round)

- Clean room: do not read {read-deny list}; do not read any other project directory outside this one.
- Do not spawn subagents, do not search the web, do not add dependencies.
- Do not commit to git or change git configuration; modify only {allowed paths}.
- {Resource rules from the environment profile: which test runs are allowed while iterating, temporary and cache directories, test database}.
- Do not run anything on shared machines named in the profile; the controller runs the full suite and performance checks.
- Write code comments in {language}.
```

## 2. Review Prompt

GPT and Gemini receive the same prompt. It embeds the full task brief, because the reviewers' configs may deny reading the directory the brief lives in.

```markdown
You are a code reviewer for this {language} repository ({one-line project description}). Read-only: do not modify, create or delete any file, and do not commit to git. You may run read-only commands and targeted tests (only the relevant individual tests; {resource rules from the environment profile}).

Review the change at the current HEAD relative to {baseline}: `git diff {baseline} HEAD` (touching only `{paths}`). The author of the change received this task brief:

----- task brief begins -----
{the brief's "Read First", "Requirements", "Invariants" and "Self-Check Requirements" sections}
----- task brief ends -----

Find the **real problems** in this change, focusing on:
1. Whether {the task's core requirement} is actually met; whether it holds only for the self-check inputs and fails on a specially constructed input. Give the concrete input.
2. Whether the self-checks are truly independent, or share a possibly wrong number with the product code.
3. Behavior changes: whether {results, errors, decisions} can differ from the baseline.
4. Newly introduced defects: correctness, edge cases, concurrency, bounded memory, obvious performance regressions, results that vary between runs.

Output: for every problem give its severity (P1 = violates a hard requirement or changes results/errors, P2 = defect with a concrete trigger, P3 = minor), file:line, the trigger (a concrete input or sequence of states), measured or estimated numbers, and the consequence. For each area where you found nothing, state "no problems found". No generic advice; do not report problems in old code unrelated to this change.

Clean-room rules: do not read {read-deny list}, do not read any other project directory outside this one, do not search the web.
```

For a fix-check round, append: "HEAD~1 is round 1 and HEAD is the round-2 fix. First check, group by group, whether each issue confirmed by the previous verification is fixed (the previous verification report's issue table is attached), then look for problems introduced in this round."

## 3. Verification Brief

```markdown
You are a **verifier**. Your job is to reproduce, one by one, the review findings a code change received and decide whether each holds. You do not change the final state of the product code; you only run experiments.

## Subject

- Working directory: `{WT}` (detached HEAD). Under review is the change at `HEAD` relative to {baseline}, concentrated in `{paths}`.
- Task requirements for the change: {one paragraph restating the hard requirements and the unit of measurement}.
- Review findings: `{FINDINGS}`, which contains two reviews, "Review X" and "Review Y". Refer to findings by their own numbers as X-1, Y-1, and so on (number unnumbered findings in order of appearance and say which passage each refers to).

## Tasks

1. Merge duplicates first: findings with the same root cause form one group; list their original numbers.
2. Run an experiment for every group and give a verdict:
   - **Confirmed**: the measurement exceeds the limit (give the measured number), or the described behavior was reproduced.
   - **Partly confirmed**: the effect exists but the numbers or severity differ from the description; give the measured number.
   - **Not confirmed**: the measurement did not reproduce it, or you can show the path is unreachable or already handled (give the code location and the measured number).
   - **Undetermined**: state where you got stuck.
   For findings about the self-check design: either construct a case where the product is wrong and the self-check still passes, or show that the self-check is truly independent on that path. Mark verdicts reached by reading code alone as "code reading only".
3. Choose your own measurement method. Recommended: **temporarily** instrument the cited loop with a counter in a temporary test file `zz_verify_*` and take the maximum difference between two checks. Restore everything afterwards.
4. Fix-check rounds: for every confirmed issue, add one sentence saying whether it was "introduced in this round", "left over from the previous round" or "present in the baseline" (read old versions with `git show HEAD~1:<file>`; do not move HEAD).

## Rules

- Clean room: {read-deny list}; under `{review materials directory}` read only the findings file above.
- Do not spawn subagents, do not use the network, do not commit to git.
- Database access: {how to reach the test database from your sandbox}. Do not start containers or proxies of your own.
- {Resource rules from the environment profile}; run only your own targeted tests. Put temporary files in `{TMPDIR}`.
- Before finishing, delete every `zz_verify_*` file and revert all instrumentation; `git status --short` must print nothing.
- Time budget is about 45 minutes; if one group takes far too long, mark it "undetermined" and explain.

## Delivery

Write the report to `{OUT}`:
- One table: group number, merged original numbers, one-line issue, verdict, measured numbers or evidence, one-line method;
- After the table, a short account of the key construction for each group, enough for someone else to redo it;
- Finally, the output of `git status --short` (which should be empty).

Your final reply needs only a few sentences: the count of each verdict and the most severe issue.
```

## 4. Rework Brief

```markdown
# Rework: fixes for the review findings on {work package} (round {N})

The change you delivered last round went through two independent reviews, and a verifier then reproduced each finding by measurement. The full verification report is attached below. (Paths in the report point to the read-only copy `{copy name}`; its content is identical to your current directory, so line numbers match directly. Do not read that directory.)

----- verification report begins -----
{full verification report}
----- verification report ends -----

## Requirements

1. **Fix every group marked "confirmed".** For "partly confirmed" groups, address every part that holds; where no change is truly needed, give the reason in the delivery notes.
2. **Cross-check.** The following issues of the same kind were found by measurement in other implementations. Check each one: fix it if present, otherwise write "checked, not present" with the code location:
   - a. {shape of the issue + approximate location}
   - b. ...
3. **Unit of measurement (controller's ruling; this takes precedence)**: {unit of measurement}.
4. **Self-checks**: add a self-check for every fixed issue (test names end in `_{suffix}R{N}`) using the construction from the verification report; give the number measured before the change; count at the actual loop sites.
5. Every requirement from the previous round still applies: {restated invariants}.

## Self-Check Commands

{the same acceptance command list as the task brief}

## Delivery

Append section "{section name}" to `{delivery notes file}`: one row for each group in the verification report and each cross-check item, giving the location, the fix, the self-check test name, and the numbers before and after the change (or "checked, not present").

## Rules (breaking any one of them voids this round)

{the same rules as the task brief, restated in full}
```

---

## 5. Spec Pre-read Brief

Send this to the tester after the spec has passed review and before the implementer starts. The goal is to surface every question the controller must rule on while the rulings can still reach the implementer's first round.

```markdown
# {work package}: spec pre-read (questions only, no tests)

You will write the black-box tests for {work package} later. This round you only read the spec and list what you could not turn into a deterministic assertion. Do not write test code. Time box: about 30 minutes.

## Read
1. {spec path}, the whole document, including rulings section {N}.
2. {default-conventions file}: anything it settles is not a question.
3. Existing tests and test scaffolding under {paths}, to see what the test build already exposes.

## List a question when
- an acceptance item names an endpoint, hook, fault point or field whose request or response shape is not given;
- a value can be read two ways (off-by-one in a formula, before or after an increment, per batch or cumulative, wrapped or bare error);
- a serialized type has no stated key names, or a time, duration or cursor has no stated format;
- an acceptance item needs a sample, hash, binary or fixture that the repository does not contain;
- an acceptance item cannot be built at the level it names (package or binary) with the interfaces the spec provides.

## Delivery
A numbered list. Each item: the acceptance item or section, the exact text that is unclear, the readings you see, and which one you would assert. Also list the acceptance items you expect to leave uncovered and why.

## Rules
{read-deny list in full}; do not read the implementer's directory; do not commit.
```

---

## 6. Default-Conventions Checklist

Every project keeps one file (for example `docs/specs/conventions.md`) that settles cross-cutting details once. A spec only mentions them when it departs from the file. In work package P1.6b, more than half of the tester's 18 questions were about items on this list.

| Item | What the file states |
|---|---|
| JSON key names | Case style for every serialized type; whether Go/TS types carry explicit tags; `omitempty` rules; empty arrays as `[]` or omitted |
| Times and durations | Format of timestamps (for example UTC RFC 3339), dates, and durations read back from the database |
| Pagination | Parameter names, default and maximum page size, cursor encoding, value on the last page, error for a bad cursor |
| Errors | Error codes and the `param` format; whether errors are wrapped with `%w`; sentinel versus typed errors and how callers test them |
| Alerts | Attribute names for consecutive count and severity; the threshold for escalation; alert body must carry the changing count |
| Backoff and retries | Formula with the exponent stated relative to the count after the increment |
| Audit records | Fields and the `result` values for success, conflict and rejection |
| Test-build surface | How hooks name their target; how fault points count (per batch or cumulative); where test-only endpoints are listed |
| Samples and golden values | Where fixed samples and their expected hashes live; who computes them |

---

## 7. Environment Profile

Every project keeps one file (its `CLAUDE.md`, or a file it points to) with everything this skill leaves to the project. The controller reads it before step 1 and copies the relevant lines into every brief; agents never have to guess them.

| Item | What the profile states |
|---|---|
| Full acceptance suite | The exact command(s) for the whole repository's tests, static checks and license or provenance scans; which steps must pass and which only report |
| Where heavy runs execute | Where the full suite, performance checks and other timing-sensitive runs execute (a dedicated build machine, a CI job, the local machine when idle), how to submit a job there and how to read its result. Results from a contended machine are not evidence for or against a performance regression |
| Performance checks | Which tests compare against a baseline, how the baseline is chosen (a release tag), and how to rule when one fails |
| Known failures | A versioned list of tests known to fail or flake, each with its cause, the environment where it fails and the package or ticket that will fix it. The full-suite run marks hits as known instead of hiding them; a known failure that stops failing is removed |
| Resources for agents | What implementers, testers, reviewers and verifiers may run while iterating; temporary and cache directories (and the sandbox write paths they need); memory or load limits before starting a large job |
| Test services | One database (or schema) per agent and how to create it; Redis or other service namespaces per agent; how a sandboxed agent reaches them; never start containers of its own |
| Read-deny list | Directories no implementer, tester or reviewer may read (other worktrees, legacy code, spec sources, credentials), restated in every brief |
| Repository rules | Branch and commit conventions, what agents may not modify (status file, specs), the language for comments and documents |
| Close-out | What the controller updates after a package merges (status file, tags, external progress pages) |

