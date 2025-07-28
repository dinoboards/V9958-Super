#!/bin/bash

set -e

# Set the version to the provided version or the current date if not provided
version=$(date +"%Y-%m-%d")

echo "Tagging current commit with '${version}'"

branch_name=$(git rev-parse --abbrev-ref HEAD)

if [[ "$branch_name" != "main" ]]; then
  echo "error: Not on main branch"
  exit 1
fi

if [ "$(git status --porcelain)" ]; then
  echo "error: Uncommitted or untracked files found.  All changes must be commit and push."
  exit 1
fi

if [ "$(git rev-list main...origin/main)" ]; then
  echo "error: Branch main has not been push to remote"
  exit 1
fi

git tag ${version}
