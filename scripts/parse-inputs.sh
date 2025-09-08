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
  REPOSITORY="$2"
  TAG="$3"

  # If tag is empty and repository is provided, check for downloaded action
  if [[ -z "$TAG" && -n "$REPOSITORY" ]]; then
    # Check if we're in a GitHub Actions environment and can use the downloaded action path
    if [[ -n "$RUNNER_WORKSPACE" ]]; then
      # Parse repository to get owner and repo
      OWNER=$(echo "$REPOSITORY" | cut -d '/' -f 1)
      REPO=$(echo "$REPOSITORY" | cut -d '/' -f 2)

      # Look for downloaded action in $(dirname "$RUNNER_WORKSPACE")/_actions/<owner>/<repo>/
      ACTIONS_DIR="$(dirname "$RUNNER_WORKSPACE")/_actions"
      ACTION_PATH="$ACTIONS_DIR/$OWNER/$REPO"

      if [[ -d "$ACTION_PATH" ]]; then
        echo "::notice::Tag not provided, checking for downloaded action at $ACTION_PATH"

        # Find the most recent directory (version/ref) in the action path
        # This could be a tag like v1.0.0 or a commit ref
        REF=$(ls -1t "$ACTION_PATH" 2>/dev/null | head -n 1)

        if [[ -n "$REF" ]]; then
          TAG="$REF"
          echo "::notice::Using downloaded action reference: $TAG"
        fi
      fi
    fi
  fi

  echo "repository=$REPOSITORY" >> $GITHUB_OUTPUT
  echo "tag=$TAG" >> $GITHUB_OUTPUT
  echo "Using repository and tag parameters: $REPOSITORY@$TAG"
fi
echo "::endgroup::"
