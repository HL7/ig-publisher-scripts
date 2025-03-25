#!/usr/bin/env bats

setup() {
  rm -f /tmp/testscript.new
  rm -f testscript
  mkdir -p test/mocks
  echo "Mock content" > test/mocks/testscript.new
}

teardown() {
  rm -f /tmp/testscript.new
  rm -f testscript
  rm -f test/mocks/testscript.new
  rm -f ./curl
}

@test "does NOT overwrite existing file if curl fails" {
  # Create a known original file
  echo "Original Content" > testscript

  # Mock curl to simulate a failed download
  cp test/mocks/fail_curl.sh ./curl
  chmod +x ./curl

  PATH="$(pwd):$PATH"
  source $SCRIPT_UNDER_TEST

  run update_script "https://example.com/testscript"

  [ "$status" -eq 0 ]  # function itself doesn't exit non-zero
  [ -f "testscript" ]

  # Ensure content was NOT changed
  run cat testscript
  [ "$output" = "Original Content" ]
}

