# Scripts Directory

This directory contains helper scripts for the Zed Windows build process.

## Build Scripts

### `Parse-Rustflags.ps1`

PowerShell script that processes Rust compilation flags for the build process.

**Purpose:**
- Parses Rust flags passed as arguments
- Sets up the build environment for different backends (Vulkan/OpenGL)
- Configures conditional compilation flags in `.cargo/config.toml`

**Usage:**
```powershell
./scripts/Parse-Rustflags.ps1 "--cfg gles"
```

**Requirements:**
- PowerShell Core or Windows PowerShell
- PSToml module (for TOML file manipulation)
- Existing `.cargo/config.toml` file

---

## Release Scripts

### `prepare-release.sh`

Main script that prepares release files from build artifacts. Handles partial build failures gracefully.

**Features:**
- Creates a `release/` directory for all output files
- Processes Vulkan build (`zed.exe`) and creates zip if available
- Processes OpenGL build (`zed-opengl.exe`) and creates zip if available
- Generates SHA256 checksums for all release files
- Fails fast if no build artifacts are found
- Uses wildcards for clean file handling

**Usage:**
```bash
./scripts/prepare-release.sh
```

**Input:**
- `artifacts/zed-release/zed.exe` (Vulkan build)
- `artifacts/zed-release-opengl/zed.exe` (OpenGL build)

**Output:**
- `release/zed.exe` and `release/zed.zip` (if Vulkan build exists)
- `release/zed-opengl.exe` and `release/zed-opengl.zip` (if OpenGL build exists)
- `release/sha256sums.txt` (checksums for all files)

**Requirements:**
- `zip` command available
- `sha256sum` command available

---

## Test Scripts

### `test-prepare-release.sh`

Comprehensive test suite for `prepare-release.sh` with full scenario coverage.

**Test Scenarios:**
- ✅ Both Vulkan and OpenGL builds present (5 files expected)
- ✅ Only Vulkan build present (3 files expected)
- ✅ Only OpenGL build present (3 files expected)
- ❌ No builds present (should fail with clear error)
- ✅ Checksum validation (verify SHA256 accuracy)
- ✅ Zip file content verification

**Usage:**
```bash
./scripts/test-prepare-release.sh
```

**Requirements:**
- `prepare-release.sh` in the same directory
- `unzip` command for zip content verification
- Temporary directory support (`mktemp`)

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