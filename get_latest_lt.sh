#!/bin/bash

set -euo pipefail

version=$(curl -fsSL https://api.github.com/repos/languagetool-org/languagetool/tags \
  | jq -er '.[0].name | ltrimstr("v")')

echo "LT_VERSION=$version" >> "$GITHUB_OUTPUT"
