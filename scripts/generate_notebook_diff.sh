#!/bin/bash
set -e

# Output file
DIFF_FILE="notebook-diff/changes.diff"
BASE_BRANCH="origin/main"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Make sure the directory exists
mkdir -p notebook-diff

# Clear the old diff
> "$DIFF_FILE"

# Get list of staged notebooks
STAGED_NOTEBOOKS=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ipynb$' || true)

if [ -z "$STAGED_NOTEBOOKS" ]; then
  echo "No notebook changes to diff."
  exit 0
fi

echo "### Notebook Diffs vs $BASE_BRANCH" > "$DIFF_FILE"

for nb in $STAGED_NOTEBOOKS; do
  if git show "$BASE_BRANCH:$nb" &>/dev/null; then
    echo -e "\n--- $nb ---\n" >> "$DIFF_FILE"
    python3 -m nbdime diff -OAMID --no-color "$CURRENT_BRANCH" -- "$nb" "$BASE_BRANCH" >> "$DIFF_FILE" || true
  fi
done

# Stage the diff file so it's included in the commit
if [ -s "$DIFF_FILE" ]; then
  git add "$DIFF_FILE"
fi
