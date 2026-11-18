# Improvement Log

How this skill keeps up with real use. These files are records, not part of the installed skill (`skills/multi-model-coding/` does not read them).

| File | What goes in | When |
|---|---|---|
| `inbox.md` | One line per process problem as it happens: date, project and package, what happened, what it cost. No rule changes yet | Immediately, by the controller |
| `packages.csv` | One row per finished work package: spec versions, acceptance items, review rounds and findings, pre-read questions, implementer rounds and time, merge failures by cause, gate failures. Empty means "not recorded", never zero | At each package's close-out; column definitions are at the top of `packages-sources.md` |
| `packages-sources.md` | Where each backfilled number came from | When rows are backfilled from old records |

## Close-out Retrospective

At every package close-out (SKILL.md workflow step 17) the controller:

1. Adds the package's row to `packages.csv`.
2. Triages every `inbox.md` line written since the last retrospective:
   - **General** (would happen on another project): change SKILL.md, a template, a script or tooling.md, and add the evidence to paradigm.md (a per-package observations section).
   - **Project-specific**: move it to that project's environment profile (templates.md section 7).
   - **Watch**: happened once at small cost; keep it in the inbox with a count.
   Remove triaged lines from the inbox.
3. Prunes: a rule that has not applied for several packages, or that the data contradicts, is reworded or removed, with the reason recorded in paradigm.md.

## Thresholds

- A new or changed rule needs either two occurrences of the problem or one costly one (hours lost, wrong data, a defect that reached a merge). The rule cites its source (package and observation).
- Changes to default models, or removing a hard rule, are proposed to the user first; other changes are reported in the next progress update.
- Every few packages (about four), one GPT review reads the whole skill for contradictions, stale statements and project-specific content that slipped in.
- Script changes run `skills/multi-model-coding/scripts/tests/run-tests.sh` before commit.
