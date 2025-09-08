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
    echo "[DEBUG] Tag is empty, checking for downloaded action..."
    echo "[DEBUG] RUNNER_WORKSPACE=$RUNNER_WORKSPACE"

    # Check if we're in a GitHub Actions environment and can use the downloaded action path
    if [[ -n "$RUNNER_WORKSPACE" ]]; then
      # Parse repository to get owner and repo
      OWNER=$(echo "$REPOSITORY" | cut -d '/' -f 1)
      REPO=$(echo "$REPOSITORY" | cut -d '/' -f 2)
      echo "[DEBUG] Owner=$OWNER, Repo=$REPO"

      # Look for downloaded action in $RUNNER_WORKSPACE/<owner>/<repo>/
      ACTION_PATH="$RUNNER_WORKSPACE/$OWNER/$REPO"
      echo "[DEBUG] Checking for action at: $ACTION_PATH"

      if [[ -d "$ACTION_PATH" ]]; then
        echo "::notice::Tag not provided, checking for downloaded action at $ACTION_PATH"

        # List all directories in the action path for debugging
        echo "[DEBUG] Contents of $ACTION_PATH:"
        ls -la "$ACTION_PATH" 2>&1 || echo "[DEBUG] Failed to list directory"

        # Find the most recent directory (version/ref) in the action path
        # This could be a tag like v1.0.0 or a commit ref
        REF=$(ls -1t "$ACTION_PATH" 2>/dev/null | head -n 1)
        echo "[DEBUG] Found REF=$REF"

        if [[ -n "$REF" ]]; then
          TAG="$REF"
          echo "::notice::Using downloaded action reference: $TAG"
        else
          echo "[DEBUG] No reference directory found in $ACTION_PATH"
        fi
      else
        echo "[DEBUG] Directory does not exist: $ACTION_PATH"
        echo "[DEBUG] Current directory: $(pwd)"
        echo "[DEBUG] RUNNER_WORKSPACE contents:"
        ls -la "$RUNNER_WORKSPACE" 2>&1 || echo "[DEBUG] Failed to list RUNNER_WORKSPACE"
      fi
    else
      echo "[DEBUG] RUNNER_WORKSPACE is not set"
    fi
  fi

  echo "repository=$REPOSITORY" >> $GITHUB_OUTPUT
  echo "tag=$TAG" >> $GITHUB_OUTPUT

  if [[ -n "$TAG" ]]; then
    echo "Using repository and tag parameters: $REPOSITORY@$TAG"
  else
    echo "Using repository parameter: $REPOSITORY (tag will be determined)"
  fi
fi
echo "::endgroup::"
