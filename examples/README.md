# Trusted Tag Verifier Examples

This directory contains example workflows for using the Trusted Tag Verifier action.

## Basic Usage

The `verify-tag.yml` workflow demonstrates how to use the action with separate repository and tag parameters:

```yaml
- name: Verify Tag
  id: verify
  uses: actionutils/trusted-tag-verifier@v1
  with:
    repository: 'owner/repo'
    tag: 'v1.0.0'
```

## Shorthand Usage

The `verify-with-shorthand.yml` workflow demonstrates how to use the action with the shorthand `verify` parameter:

```yaml
- name: Verify Tag
  id: verify
  uses: actionutils/trusted-tag-verifier@v1
  with:
    verify: 'owner/repo@v1.0.0'
```

## Using the Verification Results

Both examples demonstrate how to use the verification results in subsequent steps:

```yaml
- name: Display Verification Results
  run: |
    echo "Verified: ${{ steps.verify.outputs.verified }}"
    echo "Repository: ${{ steps.verify.outputs.repository }}"
    echo "Tag: ${{ steps.verify.outputs.tag-name }}"
    echo "Commit: ${{ steps.verify.outputs.commit-sha }}"
    echo "Tagger: ${{ steps.verify.outputs.tagger-name }} <${{ steps.verify.outputs.tagger-email }}>"
    echo "Message: ${{ steps.verify.outputs.tag-message }}"
    
    # Access specific fields from the verification result
    echo "Verification Status: $(echo '${{ steps.verify.outputs.verification-result }}' | jq -r '.verification.status')"
```

## Real-World Example

Here's a real-world example of how to use the action in a workflow that verifies a tag before using it:

```yaml
name: Verify and Use Tag

on:
  workflow_dispatch:
    inputs:
      tag:
        description: 'Tag to verify and use'
        required: true
        type: string

jobs:
  verify-and-use:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Verify Tag
        id: verify
        uses: actionutils/trusted-tag-verifier@v1
        with:
          repository: 'sigstore/gitsign'
          tag: ${{ github.event.inputs.tag }}
          fail-on-verification-error: 'false'
      
      - name: Use Tag if Verified
        if: steps.verify.outputs.verified == 'true'
        run: |
          echo "Tag ${{ steps.verify.outputs.tag-name }} is verified!"
          echo "Using commit: ${{ steps.verify.outputs.commit-sha }}"
          # Additional steps to use the verified tag
      
      - name: Handle Unverified Tag
        if: steps.verify.outputs.verified != 'true'
        run: |
          echo "Warning: Tag ${{ steps.verify.outputs.tag-name }} could not be verified!"
          echo "Verification status: $(echo '${{ steps.verify.outputs.verification-result }}' | jq -r '.verification.status')"
          echo "Errors: $(echo '${{ steps.verify.outputs.verification-result }}' | jq -r '.verification.errors')"
```

## Notes

- The action will automatically set up Gitsign for verification
- The action will fail if the tag verification fails, unless `fail-on-verification-error` is set to `false`
- The action provides detailed verification results in the `verification-result` output