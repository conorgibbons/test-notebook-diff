#!/bin/bash
set -e

echo "hiii"

# Name of master branch
MASTER_BRANCH="origin/main"

# Output file
DIFF_FILE="changelog/changes.diff"

# Make sure the directory exists
mkdir -p changelog

# Clear the old diff
> "$DIFF_FILE"

# Get list of staged notebooks
STAGED_NOTEBOOKS=$(git diff "$MASTER_BRANCH" --name-only --diff-filter=ACM | grep '\.ipynb$' || true)

if [ -z "$STAGED_NOTEBOOKS" ]; then
  echo "No notebook changes to diff."
  exit 0
fi

echo "### Notebook Diffs" > "$DIFF_FILE"

for nb in "$STAGED_NOTEBOOKS"; do
  if git cat-file -e origin/main:"$nb" 2>/dev/null; then
    echo -e "CHANGED NOTEBOOK: $nb\n" >> "$DIFF_FILE"
    python3 -m nbdime diff -OAMID --no-color <(git show "$MASTER_BRANCH":"$nb") "$nb" >> "$DIFF_FILE"
  else
    echo -e "NEW NOTEBOOK: $nb\n" >> "$DIFF_FILE"
    python3 -m nbdime diff -OAMID --no-color /dev/null "$nb" >> "$DIFF_FILE"
  fi
  echo -e "...........................\n" >> "$DIFF_FILE"
done

# # Stage the diff file so it's included in the commit
# if [ -s "$DIFF_FILE" ]; then
#   git add "$DIFF_FILE"
# fi
