#!/usr/bin/env bash

# Define the path to the script under test
SCRIPT_UNDER_TEST="${SCRIPT_UNDER_TEST:-./updatePublisher.sh}"

# Global Bats setup function
setup_suite() {
  # Export it so tests can use it
  export SCRIPT_UNDER_TEST
}
