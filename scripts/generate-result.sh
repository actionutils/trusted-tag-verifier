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

# Generate JSON using a here document
JSON=$(cat << EOF
{
  "tag": {
    "name": "$TAG",
    "commit": "$COMMIT_SHA",
    "tagger": {
      "name": "$TAGGER_NAME",
      "email": "$TAGGER_EMAIL",
      "timestamp": "$TAGGER_TIMESTAMP"
    },
    "message": "$TAG_MESSAGE"
  },
  "signature": {
    "verified": $VERIFIED,
    "timestamp": "$CURRENT_TIMESTAMP"
  },
  "cert_summary": $CERTIFICATE_SUMMARY_JSON
}
EOF
)

# Output the JSON as a single line
echo "verification-result=$(echo "$JSON" | tr -d '\n')" >> $GITHUB_OUTPUT

echo "Verification result generated successfully"
echo "::endgroup::"
