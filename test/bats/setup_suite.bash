#!/usr/bin/env bash

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in test/bats
ROOT_DIR="$( dirname "$( dirname "$ME_DIR" )" )"

# Define the path to the script under test
SCRIPT_UNDER_TEST="${SCRIPT_UNDER_TEST:-./updatePublisher.sh}"

# Global Bats setup function
setup_suite() {
  # Export it so tests can use it
  export SCRIPT_UNDER_TEST
}

teardown_suite() {
  # clean up once more

  rm -rf ${ROOT_DIR}/tmp/
  rm -f ${ROOT_DIR}/curl
}