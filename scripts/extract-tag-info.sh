#!/bin/bash
set -e

echo "::group::Extracting tag information"
# Use the temporary directory passed from the calling script or action.yml
if [[ -n "$TMP_REPO_DIR" ]]; then
  cd "$TMP_REPO_DIR"
else
  cd target-repo
fi

TAG="$1"
echo "Extracting information for tag: $TAG"

# Get tag information
TAG_REF=$(git rev-parse "$TAG" 2>/dev/null || echo "")
if [[ -z "$TAG_REF" ]]; then
  echo "Error: Could not find tag $TAG"
  exit 1
fi

# Get commit information
COMMIT_SHA=$(git rev-parse "$TAG^{commit}" 2>/dev/null || echo "")
if [[ -n "$COMMIT_SHA" ]]; then
  # Get commit author information
  COMMIT_INFO=$(git cat-file commit "$COMMIT_SHA" 2>/dev/null || echo "")
  AUTHOR_INFO=$(echo "$COMMIT_INFO" | grep "^author" | sed 's/author //' || echo "")
  TAGGER_NAME=$(echo "$AUTHOR_INFO" | sed -E 's/^([^<]+) <.+$/\1/' || echo "Unknown")
  TAGGER_EMAIL=$(echo "$AUTHOR_INFO" | sed -E 's/^.+<([^>]+)>.+$/\1/' || echo "unknown@example.com")
  
  # Extract timestamp and convert to ISO 8601 format
  UNIX_TIMESTAMP=$(echo "$AUTHOR_INFO" | sed -E 's/^.+> ([0-9]+) .+$/\1/' || echo "")
  TIMEZONE=$(echo "$AUTHOR_INFO" | sed -E 's/^.+> [0-9]+ (.+)$/\1/' || echo "+0000")
  
  if [[ -n "$UNIX_TIMESTAMP" ]]; then
    # Convert Unix timestamp to ISO 8601 format
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      TAGGER_TIMESTAMP=$(date -r "$UNIX_TIMESTAMP" -u +"%Y-%m-%dT%H:%M:%SZ")
    else
      # Linux
      TAGGER_TIMESTAMP=$(date -u -d "@$UNIX_TIMESTAMP" +"%Y-%m-%dT%H:%M:%SZ")
    fi
  else
    TAGGER_TIMESTAMP=""
  fi
  
  TAG_MESSAGE=$(echo "$COMMIT_INFO" | awk '/^$/ {p=1; next} p {print}' || echo "")
  
  echo "commit-sha=$COMMIT_SHA" >> $GITHUB_OUTPUT
  echo "tagger-name=$TAGGER_NAME" >> $GITHUB_OUTPUT
  echo "tagger-email=$TAGGER_EMAIL" >> $GITHUB_OUTPUT
  
  # For multiline outputs
  delimiter="EOF_$(date +%s)"
  echo "tagger-timestamp<<$delimiter" >> $GITHUB_OUTPUT
  echo "$TAGGER_TIMESTAMP" >> $GITHUB_OUTPUT
  echo "$delimiter" >> $GITHUB_OUTPUT
  
  echo "tag-message<<$delimiter" >> $GITHUB_OUTPUT
  echo "$TAG_MESSAGE" >> $GITHUB_OUTPUT
  echo "$delimiter" >> $GITHUB_OUTPUT
  
  echo "Tag: $TAG"
  echo "Commit: $COMMIT_SHA"
  echo "Tagger: $TAGGER_NAME <$TAGGER_EMAIL>"
  echo "Timestamp: $TAGGER_TIMESTAMP"
else
  echo "Error: Could not find commit SHA for tag $TAG"
  
  # Try to get the commit SHA directly from the tag name
  COMMIT_SHA=$(git rev-list -n 1 "$TAG" 2>/dev/null || echo "")
  if [[ -n "$COMMIT_SHA" ]]; then
    echo "Found commit SHA using rev-list: $COMMIT_SHA"
    
    # Get commit author information
    COMMIT_INFO=$(git cat-file commit "$COMMIT_SHA" 2>/dev/null || echo "")
    AUTHOR_INFO=$(echo "$COMMIT_INFO" | grep "^author" | sed 's/author //' || echo "")
    TAGGER_NAME=$(echo "$AUTHOR_INFO" | sed -E 's/^([^<]+) <.+$/\1/' || echo "Unknown")
    TAGGER_EMAIL=$(echo "$AUTHOR_INFO" | sed -E 's/^.+<([^>]+)>.+$/\1/' || echo "unknown@example.com")
    
    # Extract timestamp and convert to ISO 8601 format
    UNIX_TIMESTAMP=$(echo "$AUTHOR_INFO" | sed -E 's/^.+> ([0-9]+) .+$/\1/' || echo "")
    TIMEZONE=$(echo "$AUTHOR_INFO" | sed -E 's/^.+> [0-9]+ (.+)$/\1/' || echo "+0000")
    
    if [[ -n "$UNIX_TIMESTAMP" ]]; then
      # Convert Unix timestamp to ISO 8601 format
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        TAGGER_TIMESTAMP=$(date -r "$UNIX_TIMESTAMP" -u +"%Y-%m-%dT%H:%M:%SZ")
      else
        # Linux
        TAGGER_TIMESTAMP=$(date -u -d "@$UNIX_TIMESTAMP" +"%Y-%m-%dT%H:%M:%SZ")
      fi
    else
      TAGGER_TIMESTAMP=""
    fi
    
    TAG_MESSAGE=$(echo "$COMMIT_INFO" | awk '/^$/ {p=1; next} p {print}' || echo "")
    
    echo "commit-sha=$COMMIT_SHA" >> $GITHUB_OUTPUT
    echo "tagger-name=$TAGGER_NAME" >> $GITHUB_OUTPUT
    echo "tagger-email=$TAGGER_EMAIL" >> $GITHUB_OUTPUT
    
    # For multiline outputs
    delimiter="EOF_$(date +%s)"
    echo "tagger-timestamp<<$delimiter" >> $GITHUB_OUTPUT
    echo "$TAGGER_TIMESTAMP" >> $GITHUB_OUTPUT
    echo "$delimiter" >> $GITHUB_OUTPUT
    
    echo "tag-message<<$delimiter" >> $GITHUB_OUTPUT
    echo "$TAG_MESSAGE" >> $GITHUB_OUTPUT
    echo "$delimiter" >> $GITHUB_OUTPUT
    
    echo "Tag: $TAG"
    echo "Commit: $COMMIT_SHA"
    echo "Tagger: $TAGGER_NAME <$TAGGER_EMAIL>"
    echo "Timestamp: $TAGGER_TIMESTAMP"
  else
    echo "Error: Could not find commit SHA for tag $TAG using any method"
    exit 1
  fi
fi

echo "::endgroup::"