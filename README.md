# ZGCAI-Multi-Model-Coding

A Claude Code skill for multi-model collaborative coding. The controller owns the specification, rulings, verification and acceptance; Codex implements; an independent tester writes black-box tests from the same specification; one GPT reviewer and one Gemini reviewer each review the change blind; review findings are reproduced by measurement before any rework.

## Overview

- Defines the roles, the workflow checklist, the hard rules and the model selection for a multi-model coding workflow.
- Provides brief and prompt templates for task assignment, review, verification, rework and specification pre-reading.
- Ships helper scripts for read-only Codex reviews, blind review copies, parallel dual review, finding consolidation and scope checks.
- Is project-neutral. How a project runs its full test suite, where heavy or timing-sensitive runs take place, which directories agents may use or must not read, and which tests are known to fail all belong in that project's environment profile (template 7 in `reference/templates.md`), not in the skill.

Main components:

| Path | Contents |
|---|---|
| `skills/multi-model-coding/SKILL.md` | Roles, workflow checklist, hard rules, model selection |
| `skills/multi-model-coding/reference/templates.md` | Templates for the task brief, review prompt, verification brief, rework brief and specification pre-read brief; default-conventions checklist; environment-profile template |
| `skills/multi-model-coding/reference/tooling.md` | Codex and Devin commands, permission configurations and known pitfalls |
| `skills/multi-model-coding/reference/paradigm.md` | Full paradigm document, experiment data, the limits of that data, and per-package observations (an English edition of https://multi-model-paradigm.web.zgci.org) |
| `skills/multi-model-coding/scripts/` | `codex-review` (read-only Codex review wrapper), `make-blind-copy.sh`, `run-dual-review.sh`, `merge-findings.py`, `check-scope.sh`, sample Devin configurations, and `tests/run-tests.sh` |
| `log/` | Improvement log: process notes recorded as they occur, one metrics row per finished work package, and the procedure for updating the skill from them (`log/README.md`); not part of the installed skill |

## Getting Started

Status: experimental. Do not install the skill into the global `~/.claude/skills/` directory.

Prerequisites:

- Codex CLI (implementer and GPT reviewer) and Devin CLI (Gemini reviewer and verifiers). Devin's `--sandbox` mode requires bubblewrap and socat.
- git, bash, python3.

To evaluate the skill, link it into a single project as a project-level skill:

```bash
mkdir -p <project>/.claude/skills
ln -s "$(pwd)/skills/multi-model-coding" <project>/.claude/skills/multi-model-coding
```

`skills/multi-model-coding/scripts/tests/run-tests.sh` exercises the scripts with fake `codex` and `devin` binaries. It covers a clean dual review, a provider outage followed by a single-reviewer retry, empty answers, a Codex run that never starts, blind-copy anonymity and the scope check. It calls no model and requires no network access. Run it after any change to the scripts:

```bash
skills/multi-model-coding/scripts/tests/run-tests.sh
```

## Configuration

The scripts read the CLI binaries from environment variables, so other CLIs with the same contract can be substituted.

| Variable | Required | Default | Description |
|---|---|---|---|
| `CODEX_BIN` | No | `codex` | Codex CLI binary used by `codex-review` |
| `DEVIN_BIN` | No | `devin` | Devin CLI binary used by `run-dual-review.sh` |
| `CODEX_REVIEW` | No | `codex-review` on `PATH`, otherwise `scripts/codex-review` | Review wrapper used by `run-dual-review.sh` for the GPT reviewer |
| `START_WAIT` | No | `90` | Seconds `codex-review` waits for Codex to start before exiting with code 3 |
| `REVIEWERS` | No | `gpt gem` | Reviewers started by `run-dual-review.sh`; set to `gpt` or `gem` to rerun a single reviewer |
| `GPT_EFFORT` | No | `xhigh` | Reasoning effort for the GPT reviewer in `run-dual-review.sh` |
| `REVIEW_TIMEOUT` | No | `3600` | Time limit in seconds per reviewer in `run-dual-review.sh` |

Project-specific settings (test commands, run locations, directory rules, known failures) are recorded in the project's environment profile, following template 7 in `skills/multi-model-coding/reference/templates.md`.

## Documentation

- [`skills/multi-model-coding/SKILL.md`](skills/multi-model-coding/SKILL.md): skill entry point with roles, workflow and rules.
- [`skills/multi-model-coding/reference/templates.md`](skills/multi-model-coding/reference/templates.md): brief, prompt and environment-profile templates.
- [`skills/multi-model-coding/reference/tooling.md`](skills/multi-model-coding/reference/tooling.md): Codex and Devin commands and known pitfalls.
- [`skills/multi-model-coding/reference/paradigm.md`](skills/multi-model-coding/reference/paradigm.md): paradigm, experiment data and per-package observations.
- [`log/README.md`](log/README.md): improvement log and close-out retrospective procedure.
