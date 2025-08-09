#!/bin/bash

set -e

# Set the version to the provided version or the current date if not provided
version=${version:-$(date +"%Y-%m-%d")}

# Get the last release tag
lastRelease=$(git tag -l | sort | tail -n 1 | head -n 1)

# Define the release file path
relfile="./CHANGELOG.md"

# Remove the release file if it exists
rm -f "$relfile"

# Create the release notes file
echo -e "## Release Notes\n\n" >> "$relfile"
echo "``````" >> "$relfile"

# Append the git log to the release notes file
gitLog=$(git log --pretty=format:"%ad: %s" --date=short --submodule=short "$lastRelease..HEAD")
echo "$gitLog" >> "$relfile"

# Output the last release tag
echo "Created ./releases/CHANGELOG.md detailing changes from '${lastRelease}' to '${version}'"
