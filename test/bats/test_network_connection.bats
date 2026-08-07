#!/usr/bin/env bats

setup() {
  cp test/mocks/fail_curl.sh ./curl
  chmod +x ./curl
}

teardown() {
  rm ./curl
}

@test "fails when terminology server is unreachable" {
  PATH="$(pwd):$PATH" 
  run $SCRIPT_UNDER_TEST --yes

  [[ "$output" == *"terminology server is unreachable"* ]]
  [ "$status" -ne 0 ]
}
