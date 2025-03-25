#!/usr/bin/env bats

setup() {
  rm -rf input-cache
  mkdir -p input-cache
}

teardown() {
  # rm -rf input-cache
}

@test "detects existing publisher.jar in input-cache" {
  touch input-cache/publisher.jar
  run $SCRIPT_UNDER_TEST --yes
  [[ "$output" == *"IG Publisher FOUND in input-cache"* ]]
}

@test "detects publisher.jar in the parent directory where script is run from" {
  mkdir -p tmp/test-ig
  cp $SCRIPT_UNDER_TEST tmp/test-ig/
  echo "FAKE JAR" > tmp/publisher.jar

  pushd tmp/test-ig > /dev/null
  run $SCRIPT_UNDER_TEST --yes
  popd > /dev/null

  [[ "$output" =~ "IG Publisher FOUND in parent folder" ]]
  [ "$status" -eq 0 ]

  rm -rf tmp
}
