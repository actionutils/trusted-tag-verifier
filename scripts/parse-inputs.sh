#!/bin/bash
set -e

echo "::group::Parsing inputs"
if [[ -z "$1" ]]; then
  echo "::error::The 'verify' input is required in the format <owner>/<repo>@<version> or <owner>/<repo>"
  exit 1
fi

# Check if the input contains @ separator
if [[ "$1" == *"@"* ]]; then
  # Parse the verify input in the format <owner>/<repo>@<version>
  REPO=$(echo "$1" | cut -d '@' -f 1)
  TAG=$(echo "$1" | cut -d '@' -f 2)

  if [[ -z "$REPO" || -z "$TAG" ]]; then
    echo "::error::Invalid verify format. Expected: <owner>/<repo>@<version>, got: $1"
    exit 1
  fi

  echo "repository=$REPO" >> $GITHUB_OUTPUT
  echo "tag=$TAG" >> $GITHUB_OUTPUT
  echo "Using verify parameter: $REPO@$TAG"
else
  # No @ separator, format is <owner>/<repo>
  REPOSITORY="$1"
  TAG=""

  # Validate repository format
  if [[ ! "$REPOSITORY" =~ ^[^/]+/[^/]+$ ]]; then
    echo "::error::Invalid repository format. Expected: <owner>/<repo>, got: $REPOSITORY"
    exit 1
  fi

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

      # Find the most recent ref directory only; ignore watermark files like
      # "<ref>.completed" that the runner creates.
      # ref: https://github.com/actions/runner/blame/f9c4e17fd98db89cd9b1f05f156a9f7a8562522d/src/Runner.Worker/ActionManager.cs#L932
      latest_dir=$(ls -1td -- "$ACTION_PATH"/*/ 2>/dev/null | head -n 1)
      REF=""
      if [[ -n "$latest_dir" ]]; then
        REF="$(basename "$latest_dir")"
      fi

      if [[ -n "$REF" ]]; then
        TAG="$REF"
        echo "::notice::Using downloaded action reference: $TAG"
      else
        echo "::error::No downloaded action found for $REPOSITORY"
        exit 1
      fi
    else
      echo "::error::No @ separator provided and no downloaded action found for $REPOSITORY"
      exit 1
    fi
  else
    echo "::error::No @ separator provided and not in GitHub Actions environment"
    exit 1
  fi

  echo "repository=$REPOSITORY" >> $GITHUB_OUTPUT
  echo "tag=$TAG" >> $GITHUB_OUTPUT
  echo "Using repository with auto-detected tag: $REPOSITORY@$TAG"
fi
echo "::endgroup::"
