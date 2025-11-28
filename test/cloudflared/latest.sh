#!/bin/bash

# Test for 'latest' scenario
set -e

source dev-container-features-test-lib

check "cloudflared command exists" bash -c "command -v cloudflared"
check "cloudflared version" cloudflared --version
check "cloudflared is in /usr/local/bin" bash -c "test -x /usr/local/bin/cloudflared"

reportResults
