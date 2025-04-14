#!/bin/bash
set -e

echo "::group::Parsing inputs"
if [[ -n "$1" ]]; then
  # Parse the verify input in the format <owner>/<repo>@<version>
  REPO=$(echo "$1" | cut -d '@' -f 1)
  TAG=$(echo "$1" | cut -d '@' -f 2)
  echo "repository=$REPO" >> $GITHUB_OUTPUT
  echo "tag=$TAG" >> $GITHUB_OUTPUT
  echo "Using verify parameter: $REPO@$TAG"
else
  # Use the repository and tag inputs directly
  echo "repository=$2" >> $GITHUB_OUTPUT
  echo "tag=$3" >> $GITHUB_OUTPUT
  echo "Using repository and tag parameters: $2@$3"
fi
echo "::endgroup::"