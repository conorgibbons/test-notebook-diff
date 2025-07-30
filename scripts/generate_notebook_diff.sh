#!/bin/bash
set -e

# Output file
DIFF_FILE="changelog/changes.diff"
BASE_BRANCH="origin/main"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Make sure the directory exists
mkdir -p changelog

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
  if git cat-file -e origin/main:$nb 2>/dev/null; then
    echo -e "NOTEBOOK: $nb\n" >> "$DIFF_FILE"
    python3 -m nbdime diff -OAMID --no-color <(git show origin/main:$nb) "$nb" >> "$DIFF_FILE"
  else
    echo -e "NEW NOTEBOOK: $nb\n" >> "$DIFF_FILE"
    python3 -m nbdime diff -OAMID --no-color /dev/null "$nb" >> "$DIFF_FILE"
  fi

  echo -e "..........................." >> "$DIFF_FILE"

done

# Stage the diff file so it's included in the commit
if [ -s "$DIFF_FILE" ]; then
  git add "$DIFF_FILE"
fi
