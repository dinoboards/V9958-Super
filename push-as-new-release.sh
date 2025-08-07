#!/bin/bash

set -e

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

# Function to ask for user confirmation
ask_proceed() {
    echo
    read -p "Press any key to proceed to: '$1'." choice
}

ask_proceed "Build the firmware"
# ./build.sh

ask_proceed "Build the demo apps"
# (cd testapps && make -B -j)

ask_proceed "Generate Release Notes"
(cd ./releases && ./create-release-notes.sh)

ask_proceed "Tag current commit"
(cd ./releases && ./tag-commit.sh)

ask_proceed "Push the tag"
(cd ./releases && ./push-tag.sh)

ask_proceed "Create the draft release"
(cd ./releases && ./create-draft-release.sh)
