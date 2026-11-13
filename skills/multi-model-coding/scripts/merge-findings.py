#!/usr/bin/env python3
"""Merge two reviews of one candidate into a single unlabelled findings file.

Usage:
    merge-findings.py --gpt <codex-review output> --gem <devin final answer> \
        --out <findings.md> --mapping <mapping.txt> --label <candidate label> [--title <heading>]

- The Codex output is the full log written by `codex-review -o`; only the final
  answer (after the last "tokens used" line and the token count) is kept.
- The Devin file is the stdout of `devin -p`, which is already the final answer.
- The two reviews are written as "Review X" and "Review Y" in random order,
  so the verifier cannot tell which model wrote which. The order is appended
  to the mapping file, which must not be shown to the verifier.
"""
import argparse
import pathlib
import random
import sys


def codex_final(text: str) -> str:
    lines = text.splitlines()
    idx = [i for i, line in enumerate(lines) if line.startswith("tokens used")]
    if not idx:
        sys.exit("merge-findings: no 'tokens used' line in the Codex output; the review did not finish")
    # The line after "tokens used" is the token count; the answer follows it.
    body = "\n".join(lines[idx[-1] + 2:]).strip()
    if not body:
        sys.exit("merge-findings: empty final answer in the Codex output")
    return body


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gpt", required=True)
    ap.add_argument("--gem", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--mapping", required=True)
    ap.add_argument("--label", required=True, help="candidate label, e.g. A")
    ap.add_argument("--title", default=None)
    ap.add_argument("--seed", type=int, default=None, help="only for tests")
    a = ap.parse_args()

    gpt = codex_final(pathlib.Path(a.gpt).read_text(encoding="utf-8", errors="replace"))
    gem = pathlib.Path(a.gem).read_text(encoding="utf-8", errors="replace").strip()
    if not gem:
        sys.exit("merge-findings: the Gemini answer is empty; the review did not finish")

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
