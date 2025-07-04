#!/bin/bash
set -e

echo "::group::Verification Summary"
VERIFIED="$1"
TAG="$2"
REPOSITORY="$3"
COMMIT_SHA="$4"
TAGGER_NAME="$5"
TAGGER_EMAIL="$6"
CERTIFICATE_OIDC_ISSUER="$7"
CERTIFICATE_IDENTITY_REGEXP="$8"

# Construct GitHub URLs
REPO_URL="https://github.com/$REPOSITORY"
TAG_URL="$REPO_URL/releases/tag/$TAG"
COMMIT_URL="$REPO_URL/commit/$COMMIT_SHA"

echo "Repository: $REPOSITORY ($REPO_URL)"
echo "Tag: $TAG ($TAG_URL)"
echo "Commit: $COMMIT_SHA ($COMMIT_URL)"
echo "Tagger: $TAGGER_NAME <$TAGGER_EMAIL>"
echo "Expected Certificate OIDC Issuer: $CERTIFICATE_OIDC_ISSUER"
echo "Expected Certificate Identity Regexp: $CERTIFICATE_IDENTITY_REGEXP"
echo "Certification Summary JSON: $CERTIFICATE_SUMMARY_JSON"

if [[ "$VERIFIED" == "true" ]]; then
  echo "✅ Tag verification: SUCCESS"
else
  echo "❌ Tag verification: FAILED"
fi

# Add to GitHub step summary
echo "## Tag Verification Results" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
echo "| --- | --- |" >> $GITHUB_STEP_SUMMARY
echo "| Repository | [$REPOSITORY]($REPO_URL) |" >> $GITHUB_STEP_SUMMARY
echo "| Tag | [$TAG]($TAG_URL) |" >> $GITHUB_STEP_SUMMARY
echo "| Commit | [$COMMIT_SHA]($COMMIT_URL) |" >> $GITHUB_STEP_SUMMARY
echo "| Tagger | $TAGGER_NAME <$TAGGER_EMAIL> |" >> $GITHUB_STEP_SUMMARY
echo "| Expected Certificate OIDC Issuer | \`$CERTIFICATE_OIDC_ISSUER\` |" >> $GITHUB_STEP_SUMMARY
echo "| Expected Certificate Identity Regexp | \`$CERTIFICATE_IDENTITY_REGEXP\` |" >> $GITHUB_STEP_SUMMARY
# Parse and include certificate summary JSON if it's not empty
if [[ -n "$CERTIFICATE_SUMMARY_JSON" ]] && [[ "$CERTIFICATE_SUMMARY_JSON" != "{}" ]]; then
  # Parse JSON and add each key-value pair to the table
  echo "$CERTIFICATE_SUMMARY_JSON" | jq -r 'to_entries[] | "| \(.key) | \(.value) |"' >> $GITHUB_STEP_SUMMARY
fi

if [[ "$VERIFIED" == "true" ]]; then
  echo "| Verification | ✅ SUCCESS |" >> $GITHUB_STEP_SUMMARY
else
  echo "| Verification | ❌ FAILED |" >> $GITHUB_STEP_SUMMARY
fi

echo "::endgroup::"
