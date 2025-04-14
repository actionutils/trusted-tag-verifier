#!/bin/bash
set -e

# Default values
REPOSITORY=""
TAG=""
VERIFY=""
DEBUG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repository)
      REPOSITORY="$2"
      shift 2
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    --verify)
      VERIFY="$2"
      shift 2
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Set up environment variables for testing
export GITHUB_OUTPUT=$(mktemp)
export GITHUB_STEP_SUMMARY=$(mktemp)
export GITHUB_ACTION_PATH="$(pwd)"

# Parse inputs
echo "Parsing inputs..."
./scripts/parse-inputs.sh "$VERIFY" "$REPOSITORY" "$TAG"

# Get parsed inputs
REPOSITORY=$(grep "^repository=" "$GITHUB_OUTPUT" | cut -d= -f2)
TAG=$(grep "^tag=" "$GITHUB_OUTPUT" | cut -d= -f2)

# Validate inputs
echo "Validating inputs..."
./scripts/validate-inputs.sh "$REPOSITORY" "$TAG"

echo "Testing trusted-tag-verifier locally"
echo "Repository: $REPOSITORY"
echo "Tag: $TAG"

# Create a temporary directory for the repository
REPO_DIR=$(mktemp -d)
echo "Created temporary directory: $REPO_DIR"

# Clone the repository with shallow clone and specific tag
echo "Cloning repository with shallow clone and specific tag..."
git clone --depth 1 --branch "$TAG" "https://github.com/$REPOSITORY.git" "$REPO_DIR"
cd "$GITHUB_ACTION_PATH"

# Extract tag information
echo "Extracting tag information..."
TMP_REPO_DIR="$REPO_DIR" ./scripts/extract-tag-info.sh "$TAG"

# Get extracted tag info
COMMIT_SHA=$(grep "^commit-sha=" "$GITHUB_OUTPUT" | cut -d= -f2 || echo "")
TAGGER_NAME=$(grep "^tagger-name=" "$GITHUB_OUTPUT" | cut -d= -f2 || echo "")
TAGGER_EMAIL=$(grep "^tagger-email=" "$GITHUB_OUTPUT" | cut -d= -f2 || echo "")
TAGGER_TIMESTAMP=$(grep -A 1 "^tagger-timestamp<<" "$GITHUB_OUTPUT" | tail -n 1 || echo "")
TAG_MESSAGE=$(grep -A 1 "^tag-message<<" "$GITHUB_OUTPUT" | tail -n 1 || echo "")

# Verify the tag using gitsign
echo "Verifying tag..."
TMP_REPO_DIR="$REPO_DIR" ./scripts/verify-tag.sh "$TAG" "https://token.actions.githubusercontent.com" "^https://github.com/" "false" || true

# Get verification result
VERIFIED=$(grep "^verified=" "$GITHUB_OUTPUT" | cut -d= -f2 || echo "false")

if [[ "$VERIFIED" == "true" ]]; then
  # Extract certificate information
  echo "Extracting certificate information..."
  TMP_REPO_DIR="$REPO_DIR" ./scripts/extract-cert-info.sh "$TAG"
  
  # Get certificate info
  CERT_INFO=$(grep -A 100 "^cert-info<<" "$GITHUB_OUTPUT" | tail -n +2 | sed -n '/^EOF_/q;p' || echo "")
else
  CERT_INFO=""
fi

# Generate verification result
echo "Generating verification result..."
./scripts/generate-result.sh "$VERIFIED" "$TAG" "$COMMIT_SHA" "$TAGGER_NAME" "$TAGGER_EMAIL" "$TAGGER_TIMESTAMP" "$TAG_MESSAGE" "$CERT_INFO"

# Get verification result
VERIFICATION_RESULT=$(grep -A 100 "^verification-result<<" "$GITHUB_OUTPUT" | tail -n +2 | sed -n '/^EOF_/q;p' || echo "{}")

# Generate summary
echo "Generating summary..."
./scripts/generate-summary.sh "$VERIFIED" "$TAG" "$REPOSITORY" "$COMMIT_SHA" "$TAGGER_NAME" "$TAGGER_EMAIL"

# Display verification result
echo "Verification Result:"
echo "$VERIFICATION_RESULT" | jq || echo "$VERIFICATION_RESULT"

# Display summary
echo "Summary:"
cat "$GITHUB_STEP_SUMMARY"

# Clean up
echo "Cleaning up temporary directory: $REPO_DIR"
rm -rf "$REPO_DIR"
rm -f "$GITHUB_OUTPUT"
rm -f "$GITHUB_STEP_SUMMARY"

echo "Test completed!"