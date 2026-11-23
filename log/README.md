# Improvement Log

Records used to keep the skill aligned with real use. These files are records, not part of the installed skill; `skills/multi-model-coding/` does not read them.

## Files

| File | Contents | Updated |
|---|---|---|
| `inbox.md` | One line per process problem as it occurs: date, project and package, what happened, what it cost. No rule changes at this stage | Immediately, by the controller |
| `packages.csv` | One row per finished work package: specification versions, acceptance items, review rounds and findings, pre-read questions, implementer rounds and time, merge failures by cause, gate failures. An empty cell means "not recorded", never zero | At each package close-out; column definitions are at the top of `packages-sources.md` |
| `packages-sources.md` | Source of each backfilled number | When rows are backfilled from older records |

## Close-out Retrospective

At every package close-out (SKILL.md workflow step 17) the controller:

1. Adds the package's row to `packages.csv`.
2. Triages every `inbox.md` line written since the last retrospective:
   - **General** (would also occur on another project): change SKILL.md, a template, a script or tooling.md, and add the evidence to paradigm.md (in a per-package observations section).
   - **Project-specific**: move the line to that project's environment profile (templates.md section 7).
   - **Watch**: occurred once at small cost; keep it in the inbox with an occurrence count.

   Remove triaged lines from the inbox.
3. Prunes rules: a rule that has not applied for several packages, or that the data contradicts, is reworded or removed, and the reason is recorded in paradigm.md.

## Thresholds

- A new or changed rule requires either two occurrences of the problem or one costly occurrence (hours lost, wrong data, a defect that reached a merge). The rule cites its source (package and observation).
- Changes to default models, and removal of a hard rule, are proposed to the user first; other changes are reported in the next progress update.
- Every few packages (about four), one GPT review reads the whole skill for contradictions, stale statements and project-specific content that has slipped in.
- Script changes run `skills/multi-model-coding/scripts/tests/run-tests.sh` before commit.
