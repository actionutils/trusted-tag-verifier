#!/bin/bash
set -e

echo "::group::Validating inputs"
REPOSITORY="$1"
TAG="$2"

if [[ -z "$REPOSITORY" ]]; then
  echo "::error::Repository is required. Provide either 'verify' or 'repository' input."
  exit 1
fi

if [[ -z "$TAG" ]]; then
  echo "::error::Tag is required. Provide either 'verify' or 'tag' input."
  exit 1
fi

echo "Inputs validated successfully"
echo "Repository: $REPOSITORY"
echo "Tag: $TAG"
echo "::endgroup::"