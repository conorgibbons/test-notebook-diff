#!/usr/bin/env bash
set -e

PR_NUM=$(git rev-parse --abbrev-ref HEAD | sed 's/[^0-9]*//g')
DIFF_FILE="nb_diff/changes_for_pr_${PR_NUM:-local}.diff"

mkdir -p tmp_base tmp_head nb_diff
> "$DIFF_FILE"

# Find changed notebooks
NOTEBOOKS=$(git diff --cached --name-only | grep '\.ipynb$' || true)

for nb in $NOTEBOOKS; do
  echo "Processing $nb"

  mkdir -p "tmp_base/$(dirname "$nb")"
  mkdir -p "tmp_head/$(dirname "$nb")"

  # Get base version (last committed version)
  git show :"$nb" > "tmp_base/$nb" || continue
  nbstripout --extra-keys metadata,execution_count "tmp_base/$nb"

  # Copy staged (working copy) version
  cp "$nb" "tmp_head/$nb"
  nbstripout --extra-keys metadata,execution_count "tmp_head/$nb"

  DIFF=$(python3 -m nbdime diff --no-color "tmp_base/$nb" "tmp_head/$nb" | tail -n +4)
  if [ -n "$DIFF" ]; then
    echo -e "\n### Diff for \`$nb\`\n\`\`\`diff\n$DIFF\n\`\`\`\n---" >> "$DIFF_FILE"
  fi
done

# Stage the diff file if it was created
if [ -s "$DIFF_FILE" ]; then
  git add "$DIFF_FILE"
else
  echo "No meaningful diffs found. Skipping diff file."
  rm -f "$DIFF_FILE"
fi
