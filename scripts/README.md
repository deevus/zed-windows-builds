# Scripts Directory

This directory contains helper scripts for the Zed Windows build process.

## Scripts

### `prepare-release.sh`

Main script that prepares release files from build artifacts. This script:

- Creates a `release/` directory
- Moves Vulkan build (`zed.exe`) and creates zip if available
- Moves OpenGL build (`zed-opengl.exe`) and creates zip if available
- Generates SHA256 checksums for all release files
- Fails if no build artifacts are found

**Usage:**
```bash
./scripts/prepare-release.sh
```

**Requirements:**
- `artifacts/` directory with build outputs
- `zip` command available
- `sha256sum` command available

**Output:**
- `release/` directory containing all release files
- Files may include: `zed.exe`, `zed.zip`, `zed-opengl.exe`, `zed-opengl.zip`, `sha256sums.txt`

### `test-prepare-release.sh`

Comprehensive test suite for `prepare-release.sh`. Tests various scenarios:

- Both Vulkan and OpenGL builds present
- Only Vulkan build present
- Only OpenGL build present
- No builds present (should fail)
- Checksum validation
- Zip file content verification

**Usage:**
```bash
./scripts/test-prepare-release.sh
```

**Requirements:**
- `prepare-release.sh` must be in the same directory
- `unzip` command available for zip content verification

## Testing

To run the tests:

```bash
cd zed-windows-builds
./scripts/test-prepare-release.sh
```

The test script will create temporary directories and verify that the release preparation script works correctly in all scenarios.

## Local Testing

You can test the workflows locally using [act](https://github.com/nektos/act):

### Prerequisites
```bash
# Install act (if not already installed)
# On macOS with Homebrew:
brew install act

# Or follow installation instructions at: https://github.com/nektos/act
```

### Running Tests Locally
```bash
# Test the script unit tests
act -W .github/workflows/test.yml

# Test the integration workflows
act -W .github/workflows/test-integration.yml

# Test a specific job
act -j test-no-artifacts-failure -W .github/workflows/test-integration.yml

# Test partial failure scenarios
act -j test-partial-failure-scenarios -W .github/workflows/test-integration.yml
```

### Configuration
The repository includes a `.actrc` file with optimal settings for testing:
- Uses `linux/amd64` architecture for compatibility
- Uses `catthehacker/ubuntu:act-latest` image with all required tools

### What Gets Tested
- **Script Logic**: All branches and error conditions
- **File Handling**: Artifact processing and release file creation
- **Checksums**: SHA256 verification of all files
- **Partial Failures**: Vulkan-only, OpenGL-only, and both-builds scenarios
- **Error Cases**: No artifacts present (should fail gracefully)

## Integration

The `prepare-release.sh` script is used in the GitHub Actions workflow (`.github/workflows/release.yml`) to handle partial build failures gracefully. It ensures that releases are created even if only one of the two build variants (Vulkan or OpenGL) succeeds.