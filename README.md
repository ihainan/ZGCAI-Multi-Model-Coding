# ZGCAI Multi-Model Coding

A skill for multi-model collaborative coding: the controller owns the spec, rulings, verification and acceptance; Codex implements; one GPT and one Gemini reviewer each review the change blind; findings are reproduced by measurement before any rework.

**Status: experimental.** Do not install it into the global `~/.claude/skills/`. To try it, link it into a single project as a project-level skill:

```bash
mkdir -p <project>/.claude/skills
ln -s "$(pwd)/skills/multi-model-coding" <project>/.claude/skills/multi-model-coding
```

## Contents

| Path | Contents |
|---|---|
| `skills/multi-model-coding/SKILL.md` | Roles, workflow checklist, hard rules, model selection |
| `skills/multi-model-coding/reference/templates.md` | Task brief, review prompt, verification brief, rework brief and spec pre-read brief templates; default-conventions checklist |
| `skills/multi-model-coding/reference/tooling.md` | Codex, Devin and codex-review commands and known pitfalls |
| `skills/multi-model-coding/reference/paradigm.md` | Full paradigm document and experiment data (an English edition of https://multi-model-paradigm.web.zgci.org) |
| `skills/multi-model-coding/scripts/` | Scripts that build anonymous review copies, run the dual review in parallel and merge the findings, plus sample Devin configs for a read-only reviewer and for a verifier |

## Requirements

- Codex CLI and the local wrapper `codex-review` (`~/.local/bin/codex-review`)
- Devin CLI; `--sandbox` needs bubblewrap and socat
- git, bash, python3
