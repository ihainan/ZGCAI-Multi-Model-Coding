# ZGCAI Multi-Model Coding

A skill for multi-model collaborative coding: the controller owns the spec, rulings, verification and acceptance; Codex implements; an independent tester writes black-box tests from the same spec; one GPT and one Gemini reviewer each review the change blind; findings are reproduced by measurement before any rework.

The skill is project-neutral. How a project runs its full test suite, where heavy or timing-sensitive runs happen, which directories agents may use or must not read, and which tests are known to fail all belong in that project's **environment profile** (template 7 in `reference/templates.md`), not in the skill.

**Status: experimental.** Do not install it into the global `~/.claude/skills/`. To try it, link it into a single project as a project-level skill:

```bash
mkdir -p <project>/.claude/skills
ln -s "$(pwd)/skills/multi-model-coding" <project>/.claude/skills/multi-model-coding
```

## Contents

| Path | Contents |
|---|---|
| `skills/multi-model-coding/SKILL.md` | Roles, workflow checklist, hard rules, model selection |
| `skills/multi-model-coding/reference/templates.md` | Task brief, review prompt, verification brief, rework brief and spec pre-read brief templates; default-conventions checklist; environment-profile template |
| `skills/multi-model-coding/reference/tooling.md` | Codex and Devin commands, permission configs and known pitfalls |
| `skills/multi-model-coding/reference/paradigm.md` | Full paradigm document, experiment data, the limits of that data, and per-package observations (an English edition of https://multi-model-paradigm.web.zgci.org) |
| `log/` | Improvement log: process notes as they happen, one metrics row per finished work package, and how the skill is updated from them (`log/README.md`); not part of the installed skill |
| `skills/multi-model-coding/scripts/` | `codex-review` (read-only Codex review wrapper), `make-blind-copy.sh`, `run-dual-review.sh`, `merge-findings.py`, `check-scope.sh`, sample Devin configs, and `tests/run-tests.sh` |

## Requirements

- Codex CLI (implementer and GPT reviewer) and Devin CLI (Gemini reviewer, verifiers); Devin's `--sandbox` needs bubblewrap and socat. The scripts take the binaries from `CODEX_BIN`, `DEVIN_BIN` and `CODEX_REVIEW`, so other CLIs with the same contract can be substituted.
- git, bash, python3.

## Tests

`skills/multi-model-coding/scripts/tests/run-tests.sh` exercises the scripts with fake `codex` and `devin` binaries: a clean dual review, a provider outage followed by a single-reviewer retry, empty answers, a Codex run that never starts, blind-copy anonymity and the scope check. It calls no model and needs no network; run it after any change to the scripts.
