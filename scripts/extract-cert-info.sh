#!/bin/bash
set -e

echo "::group::Extracting certificate information"
# If TMP_REPO_DIR is set, change to that directory
if [[ -n "$TMP_REPO_DIR" ]]; then
  cd "$TMP_REPO_DIR"
fi

TAG="$1"

echo "Extracting certificate from tag..."

# Try to extract certificate information
CERT_INFO=""

# Extract from tag object
TAG_CONTENT=$(git cat-file tag "$TAG" 2>/dev/null || echo "")
if [[ -n "$TAG_CONTENT" ]]; then
  CERT_PART=$(echo "$TAG_CONTENT" | sed -n '/-BEGIN/, /-END/p' 2>/dev/null || echo "")
  if [[ -n "$CERT_PART" ]]; then
    CERT_INFO=$(echo "$CERT_PART" | sed 's/^ //g' | sed 's/gpgsig //g' | sed 's/SIGNED MESSAGE/PKCS7/g' | openssl pkcs7 -print -print_certs -text 2>/dev/null || echo "Failed to parse certificate")
		CERT_JSON=$(echo "$CERT_PART" | sed 's/^ //g' | sed 's/gpgsig //g' | sigspy -input-format=pkcs7)
  fi
fi

# If we still don't have certificate info, provide a placeholder
if [[ -z "$CERT_INFO" ]]; then
  echo "Could not extract certificate information"
  CERT_INFO="No certificate information available"
fi

# Output certificate info to stderr
echo "Certificate Information:" >&2
echo "$CERT_INFO" >&2

# For multiline outputs
delimiter="EOF_$(date +%s)"
echo "cert-info<<$delimiter" >> $GITHUB_OUTPUT
echo "$CERT_INFO" >> $GITHUB_OUTPUT
echo "$delimiter" >> $GITHUB_OUTPUT

echo "cert-json<<$delimiter" >> $GITHUB_OUTPUT
echo "$CERT_JSON" >> $GITHUB_OUTPUT
echo "$delimiter" >> $GITHUB_OUTPUT

echo "Certificate information extraction completed"
echo "::endgroup::"
