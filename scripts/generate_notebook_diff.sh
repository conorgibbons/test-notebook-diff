#!/bin/bash
set -e

# Output file
DIFF_FILE="changelog/notebooks/changes.diff"
BASE_BRANCH="master"

# Make sure the directory exists
mkdir -p changelog/notebooks

# Clear the old diff
> "$DIFF_FILE"

# Get list of staged notebooks
STAGED_NOTEBOOKS=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ipynb$' || true)

if [ -z "$STAGED_NOTEBOOKS" ]; then
  echo "No notebook changes to diff."
  exit 0
fi

echo "### Notebook Diff vs $BASE_BRANCH" > "$DIFF_FILE"

for nb in $STAGED_NOTEBOOKS; do
  if git show "$BASE_BRANCH:$nb" &>/dev/null; then
    echo -e "\n--- $nb ---\n" >> "$DIFF_FILE"
    python3 -m nbdime diff -OAMID --no-color "$BASE_BRANCH" "$nb" >> "$DIFF_FILE" || true
  fi
done

# Stage the diff file so it's included in the commit
if [ -s "$DIFF_FILE" ]; then
  git add "$DIFF_FILE"
fi
