#!/bin/bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'claude-code' feature with "version": "stable" option.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "claude command exists" which claude
check "claude version works" claude --version
check "claude help works" claude --help

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
