# Trusted Tag Verifier

A GitHub Action to verify tags signed with [Gitsign](https://github.com/sigstore/gitsign) and display their contents.

## Overview

This action verifies that Git tags are properly signed with Gitsign, extracts the tag contents, and generates a report about the verification results.

## Features

- Verify tags signed with Gitsign
- Extract and display tag information (name, commit, tagger, message)
- Extract certificate information from signed tags
- Generate detailed verification reports
- Display results in GitHub Actions step summary
- Efficient tag verification with minimal repository cloning

## Usage

### Basic Usage

```yaml
- name: Verify Tag
  uses: actionutils/trusted-tag-verifier@v1
  with:
    verify: 'owner/repo@v1.0.0'
```

### Advanced Usage

```yaml
- name: Verify Tag
  id: verify
  uses: actionutils/trusted-tag-verifier@v1
  with:
    repository: 'owner/repo'
    tag: 'v1.0.0'
    fail-on-verification-error: 'true'
    certificate-oidc-issuer: 'https://token.actions.githubusercontent.com'
    certificate-identity-regexp: '^https://github.com/'

- name: Use Verification Results
  run: |
    echo "Verified: ${{ steps.verify.outputs.verified }}"
    echo "Repository: ${{ steps.verify.outputs.repository }}"
    echo "Tag: ${{ steps.verify.outputs.tag-name }}"
    echo "Commit: ${{ steps.verify.outputs.commit-sha }}"
    echo "Tagger: ${{ steps.verify.outputs.tagger-name }} <${{ steps.verify.outputs.tagger-email }}>"
    echo "Message: ${{ steps.verify.outputs.tag-message }}"
    
    # Access specific fields from the verification result
    TAG_NAME=$(echo '${{ steps.verify.outputs.verification-result }}' | jq -r '.tag.name')
    echo "Tag name from result: $TAG_NAME"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `verify` | The repository and tag to verify in the format `<owner>/<repo>@<version>` | No | N/A |
| `repository` | The repository containing the tag to verify (ignored if `verify` is provided) | No | N/A |
| `tag` | The name of the tag to verify (ignored if `verify` is provided) | No | N/A |
| `fail-on-verification-error` | Whether to fail the action if verification fails | No | `true` |
| `certificate-oidc-issuer` | The OIDC issuer to verify against | No | `https://token.actions.githubusercontent.com` |
| `certificate-identity-regexp` | The identity regexp to verify against | No | `^https://github.com/` |

**Note**: Either `verify` OR both `repository` and `tag` must be provided.

## Outputs

| Output | Description |
|--------|-------------|
| `verified` | Whether the tag was successfully verified (true/false) |
| `repository` | The repository that was verified (e.g., 'owner/repo') |
| `tag-name` | The name of the verified tag |
| `commit-sha` | The SHA of the commit that the tag points to |
| `tagger-name` | The name of the tagger |
| `tagger-email` | The email of the tagger |
| `tag-message` | The message associated with the tag |
| `verification-result` | The complete verification result as a JSON string |

## Verification Result Format

The `verification-result` output provides a JSON object with details about the verification:

```json
{
  "tag": {
    "name": "v1.0.0",
    "commit": "abcdef1234567890abcdef1234567890abcdef12",
    "tagger": {
      "name": "John Doe",
      "email": "john.doe@example.com",
      "timestamp": "2025-04-11T12:00:00Z"
    },
    "message": "Release v1.0.0"
  },
  "signature": {
    "verified": true,
    "timestamp": "2025-04-11T12:00:00Z"
  }
}
```

## License

MIT