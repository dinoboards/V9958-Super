#!/bin/bash

# Find all .c and .h files recursively
all_files=$(find . -type f \( -name "*.c" -o -name "*.h" \))

# Get the list of files that are gitignored
git_files=$(git ls-files --others --ignored --exclude-standard --directory --no-empty-directory)

# Convert git_files to a grep pattern
grep_pattern=$(echo "$git_files" | sed 's/[.[\*^$(){}?+|]/\\&/g' | tr '\n' '|')
grep_pattern=${grep_pattern%|}

# Filter out gitignored files from all_files
files_to_format=$(echo "$all_files" | grep -v -E "$grep_pattern")

# Format the filtered files
for file in $files_to_format; do
    echo "formatting $file"
    clang-format -i "$file"
done
