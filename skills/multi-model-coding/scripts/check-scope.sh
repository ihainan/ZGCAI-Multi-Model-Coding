#!/usr/bin/env bash
# check-scope.sh — list files an implementer changed outside the paths its brief allows.
#
# Usage:
#   check-scope.sh <worktree> <base-ref> <allowed-file>
#
#   <allowed-file>  one shell glob per line, matched against repository-relative
#                   paths; "*" also matches "/" (so "internal/core/obs/*" covers
#                   the whole subtree). Blank lines and lines starting with "#"
#                   are ignored. Copy the brief's "modify only ..." list here.
#
# Checks committed changes since <base-ref>, uncommitted changes and untracked
# files. Prints every path that matches no pattern and exits 1 if there is
# any; exits 0 when everything is in scope. Run it on every delivery before
# reading the diff: implementers do make unrelated edits (one changed a test's
# Redis database number while fixing something else).
set -uo pipefail

if [ $# -ne 3 ]; then
  sed -n '2,17p' "$0" >&2
  exit 2
fi
wt=$1 base=$2 allowed=$3
[ -f "$allowed" ] || { echo "check-scope: missing $allowed" >&2; exit 2; }
git -C "$wt" rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "check-scope: unknown ref $base" >&2; exit 2; }

mapfile -t patterns < <(grep -v -E '^[[:space:]]*(#|$)' "$allowed" | sed 's/[[:space:]]*$//')
{
  git -C "$wt" diff --name-only "$base"
  git -C "$wt" ls-files --others --exclude-standard
} | sort -u | {
  bad=0
  while IFS= read -r f; do
    ok=0
    for p in "${patterns[@]}"; do
      # shellcheck disable=SC2053
      if [[ $f == $p ]]; then ok=1; break; fi
    done
    if [ $ok -eq 0 ]; then echo "out of scope: $f"; bad=1; fi
  done
  exit $bad
}
