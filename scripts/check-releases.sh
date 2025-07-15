#!/bin/bash

# Accept repository as first parameter
REPO=${1:-""}
if [ -z "$REPO" ]; then
    echo "Error: Repository parameter is required"
    echo "Usage: $0 <owner/repo>"
    exit 1
fi

# Handle GITHUB_OUTPUT for local testing
if [ -z "$GITHUB_OUTPUT" ]; then
    GITHUB_OUTPUT="/dev/stderr"
    echo "Local testing mode - outputs will be written to: $GITHUB_OUTPUT"
fi

# Get latest stable release data from the repository
UPSTREAM_RELEASE=$(gh api repos/zed-industries/zed/releases/latest --jq '{tag_name, body}')
UPSTREAM_TAG=$(echo "$UPSTREAM_RELEASE" | jq -r '.tag_name')
echo "Latest upstream release: $UPSTREAM_TAG"

# Get latest stable release tag from current repo (filter by semantic version pattern)
# Use per_page=100 to handle up to ~3 months of daily nightlies between stable releases
# If you ever have more than 100 releases between stable versions, change to --paginate
CURRENT_TAG=$(gh api repos/$REPO/releases?per_page=100 --jq '.[] | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+")) | .tag_name' | head -1)
if [ -z "$CURRENT_TAG" ]; then
    CURRENT_TAG="none"
fi
echo "Latest current repo release: $CURRENT_TAG"

# Set variables based on comparison
if [ "$UPSTREAM_TAG" != "$CURRENT_TAG" ]; then
    echo "Building stable release from upstream tag: $UPSTREAM_TAG"
    echo "build_ref=$UPSTREAM_TAG" >> $GITHUB_OUTPUT
    echo "release_tag=$UPSTREAM_TAG" >> $GITHUB_OUTPUT
    echo "should_build=true" >> $GITHUB_OUTPUT

    # Copy over the release body from the repository
    RELEASE_BODY=$(echo "$UPSTREAM_RELEASE" | jq -r '.body')
    # Use delimiter syntax for multiline outputs
    echo "release_body<<EOF" >> $GITHUB_OUTPUT
    echo "$RELEASE_BODY" >> $GITHUB_OUTPUT
    echo "EOF" >> $GITHUB_OUTPUT
else
    echo "No new stable release found, skipping build"
    echo "should_build=false" >> $GITHUB_OUTPUT
fi
