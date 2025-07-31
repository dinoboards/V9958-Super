#!/bin/bash

set -e

# Set the version to the provided version or the current date if not provided
version=$(date +"%Y-%m-%d")

gh release create ${version} --verify-tag --draft --title "$version" -F ./CHANGELOG.md ../impl/pnr/project.fs ../testapps/bin/SUPHDMI.COM ../testapps/bin/SHWS2812.COM

rm ./CHANGELOG.md

echo "Created Github Release '${version}'"

