# PR Build Trigger and Test Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable collaborators to trigger builds on PRs via `/build` comments, fix test script for new artifact paths, and add mise tooling configuration.

**Architecture:** Three independent changes: (1) GitHub Actions workflow triggered by issue comments, (2) Update bash test helpers and assertions, (3) Add mise.toml with core packages.

**Tech Stack:** GitHub Actions (issue_comment trigger), Bash (test scripts), mise (tool management)

---

### Task 1: Create PR Comment Build Trigger Workflow

**Files:**
- Create: `.github/workflows/pr-comment-build.yml`

**Step 1: Create the workflow file**

Create `.github/workflows/pr-comment-build.yml`:

```yaml
name: PR Comment Build Trigger

on:
  issue_comment:
    types: [created]

jobs:
  trigger-build:
    # Only run on PR comments (not issues)
    if: github.event.issue.pull_request != null
    runs-on: ubuntu-latest

    steps:
      - name: Check for /build command
        id: check-command
        run: |
          COMMENT="${{ github.event.comment.body }}"
          if echo "$COMMENT" | grep -q "^/build" || echo "$COMMENT" | grep -q "/build"; then
            echo "command_found=true" >> $GITHUB_OUTPUT
          else
            echo "command_found=false" >> $GITHUB_OUTPUT
          fi

      - name: Check permissions
        id: check-permissions
        if: steps.check-command.outputs.command_found == 'true'
        run: |
          ASSOCIATION="${{ github.event.comment.author_association }}"
          if [ "$ASSOCIATION" = "OWNER" ] || [ "$ASSOCIATION" = "MEMBER" ] || [ "$ASSOCIATION" = "COLLABORATOR" ]; then
            echo "has_permission=true" >> $GITHUB_OUTPUT
          else
            echo "has_permission=false" >> $GITHUB_OUTPUT
          fi

      - name: Trigger build workflow
        if: steps.check-command.outputs.command_found == 'true' && steps.check-permissions.outputs.has_permission == 'true'
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            // Get PR details
            const pr = await github.rest.pulls.get({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number
            });

            // Trigger build workflow
            await github.rest.actions.createWorkflowDispatch({
              owner: context.repo.owner,
              repo: context.repo.repo,
              workflow_id: 'build.yml',
              ref: pr.data.head.ref,
              inputs: {
                repository: pr.data.head.repo.full_name,
                ref: pr.data.head.ref
              }
            });

            console.log(`Build triggered for PR #${context.issue.number}`);
            console.log(`Repository: ${pr.data.head.repo.full_name}`);
            console.log(`Ref: ${pr.data.head.ref}`);
```

**Step 2: Verify workflow syntax**

Run: `act --list -W .github/workflows/pr-comment-build.yml`

Expected output should show the `trigger-build` job without errors.

**Step 3: Commit the workflow**

```bash
git add .github/workflows/pr-comment-build.yml
git commit -m "feat: add PR comment trigger for builds

Allow collaborators to trigger builds on PRs by commenting /build.
The workflow validates permissions and triggers build.yml with the PR's branch."
```

---

### Task 2: Fix Test Script Artifact Paths

**Files:**
- Modify: `scripts/test-prepare-release.sh:23-31`

**Step 1: Update create_dx11_artifact helper**

In `scripts/test-prepare-release.sh`, replace the `create_vulkan_artifact()` function (lines 23-26):

```bash
create_dx11_artifact() {
    mkdir -p artifacts/editor-dx11-release
    echo "fake dx11 executable" > artifacts/editor-dx11-release/zed.exe
}
```

**Step 2: Update create_opengl_artifact helper**

In `scripts/test-prepare-release.sh`, replace the `create_opengl_artifact()` function (lines 28-31):

```bash
create_opengl_artifact() {
    mkdir -p artifacts/editor-opengl-release
    echo "fake opengl executable" > artifacts/editor-opengl-release/zed.exe
}
```

**Step 3: Add create_cli_artifact helper**

In `scripts/test-prepare-release.sh`, add a new function after `create_opengl_artifact()`:

```bash
create_cli_artifact() {
    mkdir -p artifacts/cli-release
    echo "fake cli executable" > artifacts/cli-release/cli.exe
}
```

**Step 4: Verify helper functions work**

Run a quick test to verify the functions create correct paths:

```bash
cd /tmp
mkdir test-helpers && cd test-helpers
cat > test.sh << 'EOF'
#!/bin/bash
create_cli_artifact() {
    mkdir -p artifacts/cli-release
    echo "fake cli executable" > artifacts/cli-release/cli.exe
}
create_dx11_artifact() {
    mkdir -p artifacts/editor-dx11-release
    echo "fake dx11 executable" > artifacts/editor-dx11-release/zed.exe
}
create_opengl_artifact() {
    mkdir -p artifacts/editor-opengl-release
    echo "fake opengl executable" > artifacts/editor-opengl-release/zed.exe
}
create_cli_artifact
create_dx11_artifact
create_opengl_artifact
find artifacts -name "*.exe"
EOF
chmod +x test.sh
./test.sh
```

Expected output:
```
artifacts/cli-release/cli.exe
artifacts/editor-dx11-release/zed.exe
artifacts/editor-opengl-release/zed.exe
```

**Step 5: Commit helper function updates**

```bash
git add scripts/test-prepare-release.sh
git commit -m "fix: update test helper functions for new artifact paths

- Rename create_vulkan_artifact to create_dx11_artifact
- Update paths to match matrix strategy naming
- Add create_cli_artifact helper"
```

---

### Task 3: Fix Test Scenarios and Expectations

**Files:**
- Modify: `scripts/test-prepare-release.sh:72-84`
- Modify: `scripts/test-prepare-release.sh:86-93`
- Modify: `scripts/test-prepare-release.sh:95-102`

**Step 1: Update Test 1 (All builds exist)**

In `scripts/test-prepare-release.sh`, replace lines 72-84:

```bash
# Test 1: All three builds exist (CLI + DX11 + OpenGL)
setup_test "All three builds exist"
create_cli_artifact
create_dx11_artifact
create_opengl_artifact
run_test "success"
verify_file_count 7  # cli.exe, cli.zip, zed.exe, zed.zip, zed-opengl.exe, zed-opengl.zip, sha256sums.txt
verify_file_exists "release/cli.exe"
verify_file_exists "release/cli.zip"
verify_file_exists "release/zed.exe"
verify_file_exists "release/zed.zip"
verify_file_exists "release/zed-opengl.exe"
verify_file_exists "release/zed-opengl.zip"
verify_file_exists "release/sha256sums.txt"
```

**Step 2: Update Test 2 (Only DX11 build)**

In `scripts/test-prepare-release.sh`, replace lines 86-93:

```bash
# Test 2: Only DX11 build exists
setup_test "Only DX11 build exists"
create_dx11_artifact
run_test "success"
verify_file_count 3  # zed.exe, zed.zip, sha256sums.txt
verify_file_exists "release/zed.exe"
verify_file_exists "release/zed.zip"
verify_file_exists "release/sha256sums.txt"
```

**Step 3: Update Test 3 (Only OpenGL build)**

In `scripts/test-prepare-release.sh`, replace lines 95-102:

```bash
# Test 3: Only OpenGL build exists
setup_test "Only OpenGL build exists"
create_opengl_artifact
run_test "success"
verify_file_count 3  # zed-opengl.exe, zed-opengl.zip, sha256sums.txt
verify_file_exists "release/zed-opengl.exe"
verify_file_exists "release/zed-opengl.zip"
verify_file_exists "release/sha256sums.txt"
```

**Step 4: Add Test 3.5 (Only CLI build)**

In `scripts/test-prepare-release.sh`, add after Test 3:

```bash
# Test 3.5: Only CLI build exists
setup_test "Only CLI build exists"
create_cli_artifact
run_test "success"
verify_file_count 3  # cli.exe, cli.zip, sha256sums.txt
verify_file_exists "release/cli.exe"
verify_file_exists "release/cli.zip"
verify_file_exists "release/sha256sums.txt"
```

**Step 5: Update Test 4 (No builds exist) - no changes needed**

Test 4 (lines 104-113) doesn't reference specific artifact types, so no changes needed.

**Step 6: Update Test 5 (Checksum verification)**

In `scripts/test-prepare-release.sh`, replace lines 115-129:

```bash
# Test 5: Verify checksums are correct
setup_test "Checksum verification"
create_cli_artifact
create_dx11_artifact
create_opengl_artifact
run_test "success"

# Verify checksums
cd release
if sha256sum -c sha256sums.txt >/dev/null 2>&1; then
    echo "✅ Checksums are valid"
else
    echo "❌ FAIL: Checksums are invalid"
    exit 1
fi
cd ..
```

**Step 7: Update Test 6 (Zip file verification)**

In `scripts/test-prepare-release.sh`, replace lines 131-142:

```bash
# Test 6: Verify zip files contain executables
setup_test "Zip file content verification"
create_dx11_artifact
run_test "success"

# Check zip content
if unzip -l release/zed.zip | grep -q "zed.exe"; then
    echo "✅ Zip file contains executable"
else
    echo "❌ FAIL: Zip file does not contain executable"
    exit 1
fi
```

**Step 8: Run the complete test script**

Run: `./scripts/test-prepare-release.sh`

Expected: All tests pass with "🎉 All tests passed!"

**Step 9: Commit test scenario updates**

```bash
git add scripts/test-prepare-release.sh
git commit -m "fix: update test scenarios for CLI and DX11/OpenGL artifacts

- Add test for CLI-only scenario
- Rename Vulkan references to DX11
- Update all file count expectations
- Update checksum tests to include all three artifact types"
```

---

### Task 4: Add Mise Configuration

**Files:**
- Create: `.mise.toml`

**Step 1: Create .mise.toml**

Create `.mise.toml` in repository root:

```toml
[tools]
gh = "latest"
act = "latest"
shellcheck = "latest"
```

**Step 2: Verify mise recognizes the config**

Run: `mise ls`

Expected output should show:
```
gh      <version>
act     <version>
shellcheck <version>
```

**Step 3: Test tool installation**

Run: `mise install`

Expected: All three tools install successfully.

**Step 4: Verify tools are functional**

Run these commands:

```bash
mise exec -- gh --version
mise exec -- act --version
mise exec -- shellcheck --version
```

Each should output version information without errors.

**Step 5: Lint bash scripts with shellcheck**

Run: `mise exec -- shellcheck scripts/*.sh`

Expected: Either no output (no issues) or warnings that don't block functionality.

**Step 6: Commit mise configuration**

```bash
git add .mise.toml
git commit -m "feat: add mise configuration for project tools

Add gh, act, and shellcheck for consistent local development tooling."
```

---

### Task 5: Verification and Integration

**Files:**
- Read: `.github/workflows/pr-comment-build.yml`
- Read: `scripts/test-prepare-release.sh`
- Read: `.mise.toml`

**Step 1: Run all local tests**

```bash
# Run test script
./scripts/test-prepare-release.sh

# Verify workflow syntax with act
mise exec -- act --list

# Lint all bash scripts
mise exec -- shellcheck scripts/*.sh
```

Expected: All commands succeed.

**Step 2: Verify git status is clean**

Run: `git status`

Expected: "nothing to commit, working tree clean"

**Step 3: Review commit history**

Run: `git log --oneline -5`

Expected output should show 4 commits:
1. feat: add mise configuration for project tools
2. fix: update test scenarios for CLI and DX11/OpenGL artifacts
3. fix: update test helper functions for new artifact paths
4. feat: add PR comment trigger for builds

**Step 4: Push changes**

Run: `git push origin fix99`

Expected: All commits pushed successfully.

**Step 5: Test PR comment trigger**

1. Go to PR #100 on GitHub
2. Comment: `/build`
3. Check Actions tab for triggered build workflow

Expected: Build workflow starts for fix99 branch.

**Step 6: Verify build artifacts**

After build completes, check that all three artifacts were created:
- `cli-release` with cli.exe
- `editor-dx11-release` with zed.exe
- `editor-opengl-release` with zed.exe

Expected: All three artifacts exist and contain the correct executables.

---

### Task 6: Final Cleanup and Documentation

**Files:**
- Review: All modified files

**Step 1: Run integration tests on GitHub**

The test-integration.yml workflow should run automatically on push. Check that it passes.

Run: `mise exec -- gh run list --branch fix99 --limit 5`

Expected: Most recent workflow run shows success.

**Step 2: Verify no regressions**

Ensure that:
- ✅ build.yml still has correct matrix strategy
- ✅ prepare-release.sh handles all artifact combinations
- ✅ release.yml downloads and packages all artifacts
- ✅ Test scripts pass locally and in CI

**Step 3: Document completion**

All tasks complete. The fix99 branch is ready to merge to close PR #100.

Changes implemented:
1. ✅ PR comment trigger workflow (`.github/workflows/pr-comment-build.yml`)
2. ✅ Test script fixes (`scripts/test-prepare-release.sh`)
3. ✅ Mise configuration (`.mise.toml`)

---

## Notes for Engineers

**Testing Limitations:**
- Cannot run Windows builds locally on macOS using act (Windows containers not supported)
- Use act only for workflow syntax validation: `act --list`
- Full Windows build testing must happen in GitHub Actions

**Workflow Trigger Permissions:**
- Only OWNER, MEMBER, or COLLABORATOR can trigger builds via `/build`
- Silent failure if unauthorized user attempts trigger (no error message)

**Artifact Naming Convention:**
- `cli-release/cli.exe` - Command-line interface (graphics backend agnostic)
- `editor-dx11-release/zed.exe` - Editor with DirectX 11 backend
- `editor-opengl-release/zed.exe` - Editor with OpenGL backend

**Test Script:**
- Validates all combinations: all builds, partial builds, no builds
- Checks file counts, checksums, zip contents
- Run locally with: `./scripts/test-prepare-release.sh`

**Mise Tools:**
- `gh` - GitHub CLI for workflow management
- `act` - Local workflow syntax testing
- `shellcheck` - Bash script linting
