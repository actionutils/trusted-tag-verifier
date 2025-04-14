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
CERT_INFO="$8"

# Get current timestamp in ISO 8601 format
CURRENT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Generate verification result
VERIFICATION_RESULT=$(cat <<EOF
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
  }
}
EOF
)

# For multiline outputs
delimiter="EOF_$(date +%s)"
echo "verification-result<<$delimiter" >> $GITHUB_OUTPUT
echo "$VERIFICATION_RESULT" >> $GITHUB_OUTPUT
echo "$delimiter" >> $GITHUB_OUTPUT

echo "Verification result generated successfully"
echo "::endgroup::"