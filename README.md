# Trusted Tag Verifier

A GitHub Action to verify tags signed with [Gitsign](https://github.com/sigstore/gitsign) and display their contents.

## Overview

This action verifies that Git tags are properly signed with Gitsign, extracts the tag contents, and generates a report about the verification results.

## Features

- Verify tags signed with Gitsign
- Extract and display tag information (name, commit, tagger, message)
- Extract certificate information from signed tags using [sigspy](https://github.com/actionutils/sigspy)
- Generate detailed verification reports with certificate summaries
- Display results in GitHub Actions step summary
- Efficient tag verification with minimal repository cloning
- Enable custom policy validation using certificate summary data

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
    certificate-identity-regexp: '^https://github.com/actionutils/trusted-tag-releaser'

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

### Auto-Detection of Downloaded Actions

GitHub Actions automatically downloads all actions used in a workflow before execution. You can verify these actions by omitting the `tag` parameter:

```yaml
jobs:
  verify-and-use:
    runs-on: ubuntu-latest
    steps:
      # First, verify the action before using it
      - name: Verify action signature
        uses: actionutils/trusted-tag-verifier@v1
        with:
          repository: 'owner/repo'
          # Tag is auto-detected from the pre-downloaded action

      # Then use the verified action
      - name: Use the verified action
        uses: owner/repo@v1.0.0

### Custom Policy Validation

The action extracts detailed certificate information using [sigspy](https://github.com/actionutils/sigspy). You can use these fields for custom policy validation that goes beyond basic Gitsign verification:

```yaml
- name: Verify Tag with Custom Policy
  id: verify
  uses: actionutils/trusted-tag-verifier@v1
  with:
    verify: 'owner/repo@v1.0.0'

- name: Validate Git Reference Policy
  run: |
    # Validate that the tag was created from main branch
    SOURCE_REF="${{ fromJSON(steps.verify.outputs.verification-result).cert_summary.fulcio_extensions.SourceRepositoryRef }}"
    if [[ "$SOURCE_REF" != "refs/heads/main" ]]; then
      echo "❌ Tag must be created from main branch, got: $SOURCE_REF"
      exit 1
    fi

    # Validate workflow repository matches expected org
    WORKFLOW_REPO="${{ fromJSON(steps.verify.outputs.verification-result).cert_summary.fulcio_extensions.GithubWorkflowRepository }}"
    if [[ "$WORKFLOW_REPO" != your-org/* ]]; then
      echo "❌ Invalid workflow repository: $WORKFLOW_REPO"
      exit 1
    fi

    echo "✅ Custom policy validation passed"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `verify` | The repository and tag to verify in the format `<owner>/<repo>@<version>` | No | N/A |
| `repository` | The repository containing the tag to verify (ignored if `verify` is provided) | No | N/A |
| `tag` | The name of the tag to verify (ignored if `verify` is provided). If omitted and the action is already downloaded in `$RUNNER_WORKSPACE`, the action will auto-detect the tag from the downloaded action path | No | N/A |
| `fail-on-verification-error` | Whether to fail the action if verification fails | No | `true` |
| `certificate-oidc-issuer` | The OIDC issuer to verify against | No | `https://token.actions.githubusercontent.com` |
| `certificate-identity-regexp` | The identity regexp to verify against | No | `^https://github.com/actionutils/trusted-tag-releaser` |

**Note**: Either `verify` OR both `repository` and `tag` must be provided. When only `repository` is provided without `tag`, the action will attempt to auto-detect the tag from downloaded actions in the runner workspace.

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

The `verification-result` output provides a JSON object with details about the verification. The `cert_summary` field contains certificate information extracted using sigspy. Example structure:

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
  },
  "cert_summary": {
    "version": "1",
    "input": { "detectedFormat": "pkcs7" },
    "certificate": {
      "subject": { "commonName": "sigstore" },
      "issuer": { "commonName": "Fulcio" },
      "serialNumberHex": "01AB…",
      "notBefore": "2025-01-01T00:00:00Z",
      "notAfter": "2025-01-02T00:00:00Z",
      "sha256FingerprintHex": "A1B2…",
      "publicKeyAlgorithm": "RSA"
    },
    "fulcio_extensions": {
      "Issuer": "https://token.actions.githubusercontent.com",
      "GithubWorkflowTrigger": "push",
      "GithubWorkflowSHA": "6423fad6c58f6fcd38145aa5308e943325686962",
      "GithubWorkflowName": "Release",
      "GithubWorkflowRepository": "actionutils/trusted-tag-verifier",
      "GithubWorkflowRef": "refs/heads/main",
      "BuildSignerURI": "https://github.com/actionutils/trusted-tag-releaser/.github/workflows/trusted-release-workflow.yml@refs/tags/v0",
      "BuildSignerDigest": "aa7d015f1705240a9a6f58e5aabc1817f7854b47",
      "RunnerEnvironment": "github-hosted",
      "SourceRepositoryURI": "https://github.com/actionutils/trusted-tag-verifier",
      "SourceRepositoryDigest": "6423fad6c58f6fcd38145aa5308e943325686962",
      "SourceRepositoryRef": "refs/heads/main",
      "SourceRepositoryIdentifier": "965824984",
      "SourceRepositoryOwnerURI": "https://github.com/actionutils",
      "SourceRepositoryOwnerIdentifier": "206433623",
      "BuildConfigURI": "https://github.com/actionutils/trusted-tag-verifier/.github/workflows/release.yml@refs/heads/main",
      "BuildConfigDigest": "6423fad6c58f6fcd38145aa5308e943325686962",
      "BuildTrigger": "push",
      "RunInvocationURI": "https://github.com/actionutils/trusted-tag-verifier/actions/runs/16056998762/attempts/1",
      "SourceRepositoryVisibilityAtSigning": "public"
    },
    "cms": {
      "hasSignedAttributes": true,
      "signedAttributesDERBase64": "…",
      "signedAttributesSHA256Hex": "…",
      "signatureAlgorithm": "1.2.840.113549.1.1.11",
      "signatureBase64": "…"
    },
    "rekor": {
      "present": true,
      "oid": "1.3.6.1.4.1.57264.3.1",
      "transparencyLogEntry": { "logIndex": 123, "integratedTime": 1700000000, "logId": { "keyId": "…" }, "inclusionProof": { "logIndex": 123, "treeSize": 456, "rootHash": "…", "hashes": ["…"] } }
    },
    "ct": {
      "precertificateSCTs": [
        { "version": 1, "logIDHex": "…", "timestampMs": 1700000000000, "timestampRFC3339": "2023-11-14T00:00:00Z", "hashAlgorithm": "sha256", "signatureAlgorithm": "ecdsa", "signatureBase64": "…" }
      ]
    }
  }
}
```

## License

MIT
