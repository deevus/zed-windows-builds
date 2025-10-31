# PR Build Trigger and Test Fixes Design

**Date:** 2025-10-31
**Status:** Approved
**Branch:** fix99
**Related PR:** #100

## Overview

Fix remaining issues in PR #100 to enable merge. The PR implements a matrix build strategy that separates CLI and editor builds, building the CLI once and creating two editor variants (DX11 and OpenGL).

## Changes Required

### 1. PR Comment Trigger Workflow

**File:** `.github/workflows/pr-comment-build.yml`

A workflow that allows collaborators to trigger builds on PRs by commenting `/build`.

**Implementation:**
- **Trigger:** `issue_comment` event with type `created`
- **Permission Check:** Verify commenter has write access using `github.event.comment.author_association`
  - Accepted associations: `OWNER`, `MEMBER`, `COLLABORATOR`
- **PR Detection:** Only run if comment is on a PR (check `github.event.issue.pull_request` exists)
- **Command Detection:** Check if comment body contains `/build`
- **Workflow Dispatch:** Use `actions/github-script` to:
  - Fetch PR details (head repository, head ref)
  - Trigger `build.yml` workflow with PR's repository and ref
- **Feedback:** Silent operation - users check GitHub Actions tab manually

**Error Handling:**
- Skip if not a PR comment
- Skip if user lacks permissions (silent)
- Skip if `/build` not found

### 2. Test Script Fixes

**File:** `scripts/test-prepare-release.sh`

Update test helper functions and scenarios to match new artifact paths.

**Changes:**

1. **Helper Functions:**
   - Rename `create_vulkan_artifact()` → `create_dx11_artifact()`
     - Creates `artifacts/editor-dx11-release/zed.exe`
   - Update `create_opengl_artifact()`
     - Creates `artifacts/editor-opengl-release/zed.exe`
   - Add `create_cli_artifact()`
     - Creates `artifacts/cli-release/cli.exe`

2. **Test Scenarios:**
   - Test 1: All builds (CLI + DX11 + OpenGL) → 7 files
     - cli.exe, cli.zip, zed.exe, zed.zip, zed-opengl.exe, zed-opengl.zip, sha256sums.txt
   - Test 2: Only DX11 → 3 files
     - zed.exe, zed.zip, sha256sums.txt
   - Test 3: Only OpenGL → 3 files
     - zed-opengl.exe, zed-opengl.zip, sha256sums.txt
   - Test 4: Only CLI → 3 files
     - cli.exe, cli.zip, sha256sums.txt
   - Test 5: No builds → should fail
   - Test 6-7: Checksum and zip verification (unchanged)

3. **File Verification:**
   - Update all `verify_file_exists` calls to use new artifact names
   - Remove "vulkan" references

### 3. Mise Configuration

**File:** `.mise.toml` (new file in repo root)

Register project-specific tools for local development.

**Configuration:**
```toml
[tools]
gh = "latest"
act = "latest"
shellcheck = "latest"
```

**Tools:**
- **gh** - GitHub CLI for workflow triggers and PR management
- **act** - Local GitHub Actions testing (syntax validation)
- **shellcheck** - Bash script linting

**Usage:**
- Run `mise install` to install all project tools
- Tools auto-activate when in project directory

## Current State

The fix99 branch already has:
- ✅ build.yml with matrix strategy (cli, editor-dx11, editor-opengl)
- ✅ prepare-release.sh updated for new artifact paths
- ✅ release.yml updated for new artifact paths

Still needs:
- ❌ PR comment trigger workflow
- ❌ Test script fixes
- ❌ Mise configuration

## Success Criteria

1. Collaborators can comment `/build` on PRs to trigger builds
2. Test script runs successfully and validates all artifact scenarios
3. Local development tooling is consistent via mise
4. All changes merged to fix99 branch, PR #100 ready to merge

## Testing Strategy

**Local Testing (macOS):**
- Run test script: `./scripts/test-prepare-release.sh`
- Validate workflow syntax: `act --list`
- Lint bash scripts: `shellcheck scripts/*.sh`

**GitHub Actions Testing:**
- Use `/build` comment on PR #100
- Verify all three artifacts are produced
- Check artifact naming matches expectations

**Limitations:**
- Cannot run actual Windows builds locally on macOS (act doesn't support Windows containers)
- Full compilation testing must happen in GitHub Actions

## Implementation Notes

- All work done in fix99 branch
- No README updates (tabled for future work)
- Keep changes minimal to enable quick merge
- Silent operation for PR comment trigger (no bot comments)
