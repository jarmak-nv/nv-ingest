#!/bin/bash

# Exit on any error
set -e

# List of file patterns to exclude (e.g., binary files, images)
EXCLUDE_PATTERNS=".*\.(png|jpg|jpeg|gif|pdf|zip|exe|bin|log)$"

# Shannon entropy threshold (typically between 4.0 and 8.0)
ENTROPY_THRESHOLD=4.5

# Function to calculate shannon entropy
calculate_entropy() {
  local text="$1"
  awk -v str="$text" '
    function log2(x) { return log(x) / log(2) }
    BEGIN {
      n = length(str)
      for (i = 1; i <= n; i++) {
        c = substr(str, i, 1)
        freq[c]++
      }
      entropy = 0
      for (c in freq) {
        p = freq[c] / n
        entropy -= p * log2(p)
      }
      print entropy
    }
  '
}

# Get the staged files for commit
files=$(git diff --cached --name-only --diff-filter=ACMR | grep -vE "$EXCLUDE_PATTERNS")

if [ -z "$files" ]; then
  echo "No valid files to check."
  exit 0
fi

# Check each file for high entropy lines
exit_code=0
for file in $files; do
  while read -r line; do
    entropy=$(calculate_entropy "$line")
    if (( $(echo "$entropy > $ENTROPY_THRESHOLD" | bc -l) )); then
      echo "High entropy detected in file $file:"
      echo "$line"
      exit_code=1
    fi
  done < "$file"
done

exit $exit_code