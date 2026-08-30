#!/usr/bin/env bats

setup() {
  test_root=$(mktemp -d)
  fake_bin="$test_root/bin"
  mkdir -p "$fake_bin"
  output_file="$test_root/github-output"

  cat > "$fake_bin/curl" <<'EOF'
#!/bin/sh
cat <<'JSON'
[
  {"name": "v6.8"},
  {"name": "v6.7.1"}
]
JSON
EOF
  chmod +x "$fake_bin/curl"
}

teardown() {
  rm -rf "$test_root"
}

@test "extracts the newest LanguageTool tag" {
  run env PATH="$fake_bin:$PATH" GITHUB_OUTPUT="$output_file" bash ./get_latest_lt.sh

  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ "$(cat "$output_file")" = "LT_VERSION=6.8" ]
}

@test "fails when the tags response is invalid" {
  cat > "$fake_bin/curl" <<'EOF'
#!/bin/sh
echo 'not json'
EOF
  chmod +x "$fake_bin/curl"

  run env PATH="$fake_bin:$PATH" GITHUB_OUTPUT="$output_file" bash ./get_latest_lt.sh

  [ "$status" -ne 0 ]
  [ ! -s "$output_file" ]
}
