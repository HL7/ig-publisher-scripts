#!/bin/bash
#
# Run all tests 

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in test
ROOT_DIR="$( dirname "$ME_DIR" )"

# date (now)
DT=$(date +"%Y-%m-%d")

echo "Running Bats tests..."
bats ${ROOT_DIR}/test/bats/
