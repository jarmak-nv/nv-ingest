#!/usr/bin/env bash

# Exit on any error
set -e

# Check if trufflehog is installed
if ! command -v trufflehog &> /dev/null; then
    echo "trufflehog is not installed. Please install it with 'pip install trufflehog'."
    exit 1
fi

# Exclude files containing "placeholder"
EXCLUDE_PATTERN="placeholder"

# Get a list of files that are staged for commit
files=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$files" ]; then
  echo "No files staged for commit."
  exit 0
fi

# Run trufflehog scan on each staged file, excluding files with the "placeholder" in the name or path
exit_code=0
for file in $files; do
  if [[ "$file" == *"$EXCLUDE_PATTERN"* ]]; then
    echo "Skipping $file (contains 'placeholder')"
    continue
  fi

  echo "Scanning $file with trufflehog..."
  
  # Scan the file with trufflehog
  trufflehog filesystem --no-update --only-verified-true "$file"
  
  # Capture the result of trufflehog and set exit code
  if [ $? -ne 0 ]; then
    echo "Potential secret detected in $file"
    exit_code=1
  fi
done

exit $exit_code
