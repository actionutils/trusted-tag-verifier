#!/bin/bash
set -e

echo "::group::Generating verification result"
VERIFIED="$1"
TAG="$2"
COMMIT_SHA="$3"
TAGGER_NAME="$4"
TAGGER_EMAIL="$5"
TAGGER_TIMESTAMP="$6"
TAG_MESSAGE="$7"

# Get current timestamp in ISO 8601 format
CURRENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Generate JSON using jq to properly escape strings
JSON=$(jq -n \
  --arg tag "$TAG" \
  --arg commit "$COMMIT_SHA" \
  --arg tagger_name "$TAGGER_NAME" \
  --arg tagger_email "$TAGGER_EMAIL" \
  --arg tagger_timestamp "$TAGGER_TIMESTAMP" \
  --arg tag_message "$TAG_MESSAGE" \
  --argjson verified "$VERIFIED" \
  --arg current_timestamp "$CURRENT_TIMESTAMP" \
  --argjson cert_summary "${CERTIFICATE_SUMMARY_JSON:-{}}" \
  '{
    tag: {
      name: $tag,
      commit: $commit,
      tagger: {
        name: $tagger_name,
        email: $tagger_email,
        timestamp: $tagger_timestamp
      },
      message: $tag_message
    },
    signature: {
      verified: $verified,
      timestamp: $current_timestamp
    },
    cert_summary: $cert_summary
  }')

# Output the JSON as a single line
echo "verification-result=$(echo "$JSON" | tr -d '\n')" >> $GITHUB_OUTPUT

echo "Verification result generated successfully"
echo "::endgroup::"
