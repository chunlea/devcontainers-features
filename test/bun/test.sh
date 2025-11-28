#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'bun' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "bun": {}
#    },
#    "remoteUser": "root"
# }
#
# Thus, the value of all options will fall back to the default value in
# the Feature's 'devcontainer-feature.json'.
# For the 'bun' feature, that means the default version is 'latest'.
#
# This test can be run with the following command:
#
#    devcontainer features test    \
#               --features bun   \
#               --remote-user root \
#               --skip-scenarios   \
#               --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#               /path/to/this/repo

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "bun command exists" bash -c "command -v bun"
check "bun version" bun --version
check "bun help works" bun --help

# Report results
reportResults
