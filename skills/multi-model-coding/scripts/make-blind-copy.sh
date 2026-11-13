#!/usr/bin/env bash
# make-blind-copy.sh — build an anonymous, read-only review copy of one candidate.
#
# Usage:
#   make-blind-copy.sh <source-repo> <base-ref> <dest-dir> <commit> [<commit> ...]
#
#   <source-repo>  repository (or worktree) that contains the candidate commits
#   <base-ref>     baseline the candidate started from, e.g. main
#   <dest-dir>     new directory to create; must not exist
#   <commit>...    one commit per round, oldest first. Each round's change
#                  (previous commit -> this commit) becomes one neutral commit,
#                  so HEAD~1 is round 1 and HEAD is round 2, and so on.
#
# Why not a git worktree: a worktree shares refs with the source repository,
# so `git branch -a` or `git log --all` in the copy reveals the implementer's
# branch names. This script makes an independent clone that carries only the
# baseline branch, no remote, a neutral author and neutral commit messages,
# and leaves the copy on a detached HEAD.
#
# Environment:
#   BLIND_AUTHOR   author for the neutral commits (default "candidate <candidate@localhost>")
#   BLIND_MSG_1..  optional message per round (default "candidate: round N")
#   BLIND_BASE_NAME  branch name for the baseline inside the copy (default:
#                  <base-ref> when it is a branch name, otherwise "main")
set -euo pipefail

if [ $# -lt 4 ]; then
  sed -n '2,24p' "$0" >&2
  exit 2
fi
src=$1 base=$2 dest=$3
shift 3

if [ -e "$dest" ]; then
  echo "make-blind-copy: $dest already exists" >&2
  exit 2
fi
base_sha=$(git -C "$src" rev-parse --verify "$base^{commit}")
for c in "$@"; do git -C "$src" rev-parse --verify "$c^{commit}" >/dev/null; done

author=${BLIND_AUTHOR:-"candidate <candidate@localhost>"}
name=${author% <*}
email=${author##*<}; email=${email%>}

# --no-local copies objects instead of hard-linking; --single-branch keeps
# only the baseline branch, so no candidate branch name enters the copy.
# A commit hash cannot be passed to --branch; fall back to a full clone,
# whose extra refs are deleted below.
git clone --quiet --no-local --single-branch --branch "$base" "$src" "$dest" 2>/dev/null \
  || git clone --quiet --no-local "$src" "$dest"
git -C "$dest" checkout --quiet --detach "$base_sha"
git -C "$dest" remote remove origin
# Drop every local branch and tag so only the detached history remains.
git -C "$dest" for-each-ref --format='%(refname)' refs/heads refs/tags refs/remotes \
  | while read -r ref; do git -C "$dest" update-ref -d "$ref"; done
git -C "$dest" reflog expire --expire=now --all
git -C "$dest" gc --quiet --prune=now

prev=$base_sha
n=0
for c in "$@"; do
  n=$((n + 1))
  msg_var="BLIND_MSG_$n"
  msg=${!msg_var:-"candidate: round $n"}
  git -C "$src" diff --binary "$prev" "$c" | git -C "$dest" apply --index --whitespace=nowarn
  GIT_AUTHOR_NAME=$name GIT_AUTHOR_EMAIL=$email GIT_COMMITTER_NAME=$name GIT_COMMITTER_EMAIL=$email \
    git -C "$dest" commit --quiet --allow-empty -m "$msg"
  prev=$c
done

# Recreate the baseline name so reviewers can run `git diff <base> HEAD`.
# The branch is fixed at the baseline commit, so later moves of the source
# repository's main cannot change what the reviewer sees.
if [ -z "${BLIND_BASE_NAME:-}" ]; then
  if git -C "$src" show-ref --verify --quiet "refs/heads/$base"; then BLIND_BASE_NAME=$base; else BLIND_BASE_NAME=main; fi
fi
git -C "$dest" branch --quiet "$BLIND_BASE_NAME" "$base_sha"

# Self-check: the copy's tree must equal the last candidate commit's tree.
want=$(git -C "$src" rev-parse "$prev^{tree}")
got=$(git -C "$dest" rev-parse "HEAD^{tree}")
if [ "$want" != "$got" ]; then
  echo "make-blind-copy: tree mismatch (want $want, got $got)" >&2
  exit 1
fi
echo "blind copy ready: $dest (HEAD $(git -C "$dest" rev-parse --short HEAD), $n round(s) on $base)"
git -C "$dest" branch -a
