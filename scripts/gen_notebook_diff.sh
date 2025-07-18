#!/usr/bin/env bash
set -euo pipefail

# Clean up temp dirs on exit
trap 'rm -rf tmp_base tmp_head' EXIT

# Determine PR number from branch name (fallback to "local" if none)
PR_NUM=$(git rev-parse --abbrev-ref HEAD | sed 's/[^0-9]*//g')
DIFF_FILE="nb_diff/changes_for_pr_${PR_NUM:-local}.diff"

mkdir -p tmp_base tmp_head nb_diff
> "$DIFF_FILE"

# Find staged .ipynb files
NOTEBOOKS=$(git diff --cached --name-only | grep '\.ipynb$' || true)

if [ -z "$NOTEBOOKS" ]; then
  echo "No changed notebooks to diff."
  exit 0
fi

for nb in $NOTEBOOKS; do
  echo "Processing $nb"

  # Ensure subdirectories exist
  mkdir -p "tmp_base/$(dirname "$nb")"
  mkdir -p "tmp_head/$(dirname "$nb")"

  # Get base version from Git (staged version)
  git show :"$nb" > "tmp_base/$nb" || continue
  nbstripout --extra-keys metadata,execution_count "tmp_base/$nb"

  # Copy working version
  cp "$nb" "tmp_head/$nb"
  nbstripout --extra-keys metadata,execution_count "tmp_head/$nb"

  # Generate and filter diff
  DIFF=$(python3 -m nbdime diff --no-color "tmp_base/$nb" "tmp_head/$nb" | tail -n +4)
  if [ -n "$DIFF" ]; then
    echo -e "\n### Diff for \`$nb\`\n\`\`\`diff\n$DIFF\n\`\`\`\n---" >> "$DIFF_FILE"
  else
    echo "No meaningful diff in $nb"
  fi
done

# Stage the diff file if it exists and has content
if [ -s "$DIFF_FILE" ]; then
  git add "$DIFF_FILE"
  echo "Notebook diff written to $DIFF_FILE and staged for commit."
else
  rm -f "$DIFF_FILE"
  echo "No meaningful diffs found. Nothing to stage."
fi
