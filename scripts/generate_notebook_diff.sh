#!/bin/bash
set -e

# Remove old file if it exists
rm -f changelog/notebooks/changes.diff

# Start fswatch in the background and log events
FSWATCH_LOG="/tmp/fswatch-notebooks.log"
: > "$FSWATCH_LOG"

fswatch --event Created --event Updated --event Removed changelog/notebooks/changes.diff >> "$FSWATCH_LOG" &
FSWATCH_PID=$!

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
    echo -e "\n--- $nb ---\n" >> "$DIFF_FILE"
    python3 -m nbdime diff -OAMID --no-color <(git show origin/main:$nb) "$nb" >> "$DIFF_FILE"
  else
    python3 -m nbdime diff -OAMID --no-color /dev/null "$nb" >> "$DIFF_FILE"
  fi

  echo -e "\n\n" >> "$DIFF_FILE"

done

# Stage the diff file so it's included in the commit
if [ -s "$DIFF_FILE" ]; then
  git add "$DIFF_FILE"
fi

# Kill fswatch after the script runs
kill $FSWATCH_PID

# If the file was touched, print who did it
if [ -s "$FSWATCH_LOG" ]; then
    echo "📦 changelog/notebooks/changes.diff was created or modified:"
    cat "$FSWATCH_LOG"
fi
