#!/usr/bin/env python3
"""Merge two reviews of one candidate into a single unlabelled findings file.

Usage:
    merge-findings.py --prefix <out-prefix of run-dual-review.sh> \
        --out <findings.md> --mapping <mapping.txt> --label <candidate label> [--title <heading>]

- Refuses to merge unless <prefix>-gpt.status and <prefix>-gem.status both
  record exit=0 for the latest run of each reviewer. A failed or never-run
  review is never turned into findings, whatever text its output file holds.
- The Codex answer is taken from the full log <prefix>-gpt.txt written by
  `codex-review -o`: the text after the last "tokens used" line and its count.
- The Devin answer is <prefix>-gem.txt, the stdout of `devin -p` (stderr goes
  to <prefix>-gem.log and is never read here).
- The two reviews are written as "Review X" and "Review Y" in random order,
  so the verifier cannot tell which model wrote which. The order is appended
  to the mapping file, which must not be shown to the verifier.
"""
import argparse
import pathlib
import random
import sys


def fail(msg: str) -> None:
    sys.exit(f"merge-findings: {msg}")


def check_status(prefix: str, who: str) -> None:
    p = pathlib.Path(f"{prefix}-{who}.status")
    if not p.is_file():
        fail(f"{p} is missing; the {who} review was not run or did not finish")
    line = p.read_text(encoding="utf-8", errors="replace").strip()
    if not line.startswith("exit=0 "):
        fail(f"{who} review did not succeed ({line}); rerun it with REVIEWERS={who}")


def codex_final(text: str) -> str:
    lines = text.splitlines()
    idx = [i for i, line in enumerate(lines) if line.startswith("tokens used")]
    if not idx:
        fail("no 'tokens used' line in the Codex log; the review did not finish")
    # The line after "tokens used" is the token count; the answer follows it.
    body = "\n".join(lines[idx[-1] + 2:]).strip()
    if not body:
        fail("empty final answer in the Codex log")
    return body


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--prefix", required=True, help="the <out-prefix> given to run-dual-review.sh")
    ap.add_argument("--out", required=True)
    ap.add_argument("--mapping", required=True)
    ap.add_argument("--label", required=True, help="candidate label, e.g. A")
    ap.add_argument("--title", default=None)
    ap.add_argument("--seed", type=int, default=None, help="only for tests")
    a = ap.parse_args()

    for who in ("gpt", "gem"):
        check_status(a.prefix, who)
    gpt = codex_final(pathlib.Path(f"{a.prefix}-gpt.txt").read_text(encoding="utf-8", errors="replace"))
    gem = pathlib.Path(f"{a.prefix}-gem.txt").read_text(encoding="utf-8", errors="replace").strip()
    if not gem:
        fail("the Gemini answer is empty; the review did not finish")

    rng = random.Random(a.seed)
    pair = [("gpt", gpt), ("gem", gem)]
    rng.shuffle(pair)

    title = a.title or f"Two reviews of candidate {a.label} (sources not disclosed)"
    doc = f"# {title}\n\n## Review X\n\n{pair[0][1]}\n\n## Review Y\n\n{pair[1][1]}\n"
    pathlib.Path(a.out).write_text(doc, encoding="utf-8")
    with open(a.mapping, "a", encoding="utf-8") as f:
        f.write(f"{a.label}: X={pair[0][0]} Y={pair[1][0]}\n")
    print(f"wrote {a.out} ({len(doc)} chars); mapping appended to {a.mapping}")


if __name__ == "__main__":
    main()
