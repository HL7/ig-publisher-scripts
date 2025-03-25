# Testing the shell scripts

The information below is intended for testing the shell scripts in this repository.
These tests are NOT necessary for regular users that want to simply use the scripts
to work with the FHIR IG Publisher.
They are only intended for people wanting to improve the scripts and want a simple way
to test the various options.

## Requirements

This test script use `expect` and [`bats` Bash Automated Testing System](https://github.com/bats-core/bats-core). `expect` is part of bash, but `bats` is not and usually not by default present on a machine. Use the relevant instruction below to install it.

```shell
brew install bats-core      # macOS
sudo apt install bats       # Ubuntu
```

## Running the tests

All tests can be found in the `test` directory. This directory also contains a script to run all the tests at once.
