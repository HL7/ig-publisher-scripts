#!/usr/bin/env bats

setup() {
  rm -rf input-cache
}

teardown() {
  rm -rf input-cache
}

@test "displays help message with --help" {
  run $SCRIPT_UNDER_TEST --help
  [[ "$output" == *"Usage:"* ]]
  [ "$status" -eq 0 ]
}

@test "creates input-cache with --yes" {
  run $SCRIPT_UNDER_TEST --yes
  [ -d "input-cache" ]
  [ "$status" -eq 0 ]
}

@test "runs without prompts using --force and --skip" {
  run $SCRIPT_UNDER_TEST --force --skip
  [ "$status" -eq 0 ]
}
