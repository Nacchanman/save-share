#!/usr/bin/env bash
set -euo pipefail

# Resolve the known Save & Share PR conflicts by keeping this branch's app files.
# Usage from the PR branch after a failed merge/rebase:
#   git merge origin/main
#   scripts/resolve-save-share-conflicts.sh
#   git commit

files=(
  "SaveShare/ArticleCardView.swift"
  "SaveShare/ContentView.swift"
  "SaveShare/Models.swift"
  "SaveShare/SaveShareStore.swift"
  "src/main.js"
  "src/styles.css"
)

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Run this script inside the save-share git repository." >&2
  exit 1
fi

cd "$(git rev-parse --show-toplevel)"

unmerged=$(git diff --name-only --diff-filter=U || true)
if [[ -z "$unmerged" ]]; then
  echo "No unmerged files found. Nothing to resolve."
  exit 0
fi

for file in "${files[@]}"; do
  if grep -qx "$file" <<<"$unmerged"; then
    echo "Keeping PR branch version: $file"
    git checkout --ours -- "$file"
    git add "$file"
  fi
done

remaining=$(git diff --name-only --diff-filter=U || true)
if [[ -n "$remaining" ]]; then
  echo "These files still need manual conflict resolution:" >&2
  echo "$remaining" >&2
  exit 1
fi

echo "Save & Share conflicts resolved. Review the result, then run: git commit"
