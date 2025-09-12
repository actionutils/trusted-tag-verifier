#!/bin/bash
set -e

echo "::group::Parsing inputs"
if [[ -z "$1" ]]; then
  echo "::error::The 'verify' input is required in the format <owner>/<repo>@<version>"
  exit 1
fi

# Parse the verify input in the format <owner>/<repo>@<version>
REPO=$(echo "$1" | cut -d '@' -f 1)
TAG=$(echo "$1" | cut -d '@' -f 2)

if [[ -z "$REPO" || -z "$TAG" || "$REPO" == "$TAG" ]]; then
  echo "::error::Invalid verify format. Expected: <owner>/<repo>@<version>, got: $1"
  exit 1
fi

echo "repository=$REPO" >> $GITHUB_OUTPUT
echo "tag=$TAG" >> $GITHUB_OUTPUT
echo "Using verify parameter: $REPO@$TAG"
echo "::endgroup::"
