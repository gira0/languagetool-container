#!/usr/bin/env bats

setup() {
  test_root=$(mktemp -d)
  fake_bin="$test_root/bin"
  mkdir -p "$fake_bin"
}

teardown() {
  rm -rf "$test_root"
  rm -f response_body.json
}

@test "requires an image reference" {
  run bash ./healthcheck.sh

  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "accepts a healthy container with enough languages" {
  cat > "$fake_bin/podman" <<'EOF'
#!/bin/sh
case "$1" in
  run) echo container-id ;;
  stop) exit 0 ;;
  *) exit 1 ;;
esac
EOF
  cat > "$fake_bin/curl" <<'EOF'
#!/bin/sh
printf '[%s]\n' "$(printf 'null,%.0s' $(seq 1 50) | sed 's/,$//')" > response_body.json
printf '200'
EOF
  cat > "$fake_bin/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$fake_bin/podman" "$fake_bin/curl" "$fake_bin/sleep"

  run env PATH="$fake_bin:$PATH" bash ./healthcheck.sh example/languagetool:nightly

  [ "$status" -eq 0 ]
  [[ "$output" == *"Status code: 200"* ]]
  [[ "$output" == *"Language count:"* ]]
}
