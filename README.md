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

When using an action that's already been downloaded in the workflow, you can omit the `tag` parameter and let the verifier auto-detect it:

```yaml
- name: Use an action (this downloads it)
  uses: owner/repo@v1.0.0

- name: Verify the downloaded action
  uses: actionutils/trusted-tag-verifier@v1
  with:
    repository: 'owner/repo'
    # Tag is auto-detected from the downloaded action

### Custom Policy Validation

The action extracts detailed certificate information using [sigspy](https://github.com/actionutils/sigspy), enabling custom policy validation that goes beyond basic Gitsign verification:

```yaml
- name: Verify Tag with Custom Policy
  id: verify
  uses: actionutils/trusted-tag-verifier@v1
  with:
    verify: 'owner/repo@v1.0.0'

- name: Validate Git Reference Policy
  run: |
    # Validate that the tag was created from main branch
    SOURCE_REF="${{ fromJSON(steps.verify.outputs.verification-result).cert_summary.SourceRepositoryRef }}"
    if [[ "$SOURCE_REF" != "refs/heads/main" ]]; then
      echo "❌ Tag must be created from main branch, got: $SOURCE_REF"
      exit 1
    fi

    # Validate workflow repository matches expected org
    WORKFLOW_REPO="${{ fromJSON(steps.verify.outputs.verification-result).cert_summary.GithubWorkflowRepository }}"
    if [[ "$WORKFLOW_REPO" != "your-org/"* ]]; then
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

The `verification-result` output provides a JSON object with details about the verification. The `cert_summary` field contains detailed certificate information extracted using [sigspy](https://github.com/actionutils/sigspy), which can be used for custom policy validation:

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
    "BuildConfigDigest": "2f0158cee2ca80feda6a0e13395d35f45613240c",
    "BuildConfigURI": "https://github.com/actionutils/trusted-tag-verifier/.github/workflows/release.yml@refs/heads/main",
    "BuildSignerDigest": "1b72eaca3cace8970af9c4beeb605b5769db40ef",
    "BuildSignerURI": "https://github.com/actionutils/trusted-tag-releaser/.github/workflows/trusted-release-workflow.yml@refs/tags/v0",
    "BuildTrigger": "push",
    "GithubWorkflowName": "Release",
    "GithubWorkflowRef": "refs/heads/main",
    "GithubWorkflowRepository": "actionutils/trusted-tag-verifier",
    "GithubWorkflowSHA": "2f0158cee2ca80feda6a0e13395d35f45613240c",
    "GithubWorkflowTrigger": "push",
    "Issuer": "https://token.actions.githubusercontent.com",
    "RunInvocationURI": "https://github.com/actionutils/trusted-tag-verifier/actions/runs/14438795385/attempts/1",
    "RunnerEnvironment": "github-hosted",
    "SourceRepositoryDigest": "2f0158cee2ca80feda6a0e13395d35f45613240c",
    "SourceRepositoryIdentifier": "965824984",
    "SourceRepositoryOwnerIdentifier": "206433623",
    "SourceRepositoryOwnerURI": "https://github.com/actionutils",
    "SourceRepositoryRef": "refs/heads/main",
    "SourceRepositoryURI": "https://github.com/actionutils/trusted-tag-verifier",
    "SourceRepositoryVisibilityAtSigning": "public"
  }
}
```

## License

MIT
