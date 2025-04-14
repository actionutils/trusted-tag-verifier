#!/bin/bash
set -e

echo "::group::Verification Summary"
VERIFIED="$1"
TAG="$2"
REPOSITORY="$3"
COMMIT_SHA="$4"
TAGGER_NAME="$5"
TAGGER_EMAIL="$6"

echo "Repository: $REPOSITORY"
echo "Tag: $TAG"
echo "Commit: $COMMIT_SHA"
echo "Tagger: $TAGGER_NAME <$TAGGER_EMAIL>"

if [[ "$VERIFIED" == "true" ]]; then
  echo "✅ Tag verification: SUCCESS"
else
  echo "❌ Tag verification: FAILED"
fi

# Add to GitHub step summary
echo "# Tag Verification Results" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
echo "| --- | --- |" >> $GITHUB_STEP_SUMMARY
echo "| Repository | $REPOSITORY |" >> $GITHUB_STEP_SUMMARY
echo "| Tag | $TAG |" >> $GITHUB_STEP_SUMMARY
echo "| Commit | $COMMIT_SHA |" >> $GITHUB_STEP_SUMMARY
echo "| Tagger | $TAGGER_NAME <$TAGGER_EMAIL> |" >> $GITHUB_STEP_SUMMARY

if [[ "$VERIFIED" == "true" ]]; then
  echo "| Verification | ✅ SUCCESS |" >> $GITHUB_STEP_SUMMARY
else
  echo "| Verification | ❌ FAILED |" >> $GITHUB_STEP_SUMMARY
fi

echo "::endgroup::"