#!/bin/bash
set -e

echo "::group::Verifying tag with Gitsign"
# If TMP_REPO_DIR is set, change to that directory
if [[ -n "$TMP_REPO_DIR" ]]; then
  cd "$TMP_REPO_DIR"
fi

TAG="$1"
CERTIFICATE_OIDC_ISSUER="$2"
CERTIFICATE_IDENTITY_REGEXP="$3"
FAIL_ON_ERROR="$4"

echo "Verifying tag $TAG..."

# Check if gitsign is installed
if ! command -v gitsign &> /dev/null; then
  echo "::error::gitsign command not found"
  exit 1
fi

# Check if the tag exists
if ! git show-ref --tags "$TAG" > /dev/null 2>&1; then
  echo "::error::Tag $TAG not found"
  exit 1
fi

# Try to verify the tag
if gitsign verify-tag \
  --certificate-oidc-issuer="$CERTIFICATE_OIDC_ISSUER" \
  --certificate-identity-regexp="$CERTIFICATE_IDENTITY_REGEXP" \
  "$TAG" 2>/dev/null; then
  
  echo "✅ Tag verification successful!"
  echo "verified=true" >> $GITHUB_OUTPUT
else
  echo "❌ Tag verification failed or tag is not signed with Gitsign."
  echo "verified=false" >> $GITHUB_OUTPUT
  
  if [[ "$FAIL_ON_ERROR" == "true" ]]; then
    echo "::error::Tag verification failed"
    exit 1
  fi
fi
echo "::endgroup::"