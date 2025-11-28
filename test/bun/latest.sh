#!/bin/bash

# Test for 'latest' scenario
set -e

source dev-container-features-test-lib

check "bun command exists" bash -c "command -v bun"
check "bun version" bun --version
check "bunx command exists" bash -c "command -v bunx"

reportResults
