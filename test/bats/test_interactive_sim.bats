#!/usr/bin/env bats

setup() {
  rm -rf input-cache testscript publisher.jar
}

teardown() {
  rm -rf input-cache testscript publisher.jar ./curl
}

@test "creates input-cache directory with --yes" {
  run $SCRIPT_UNDER_TEST --yes
  [ "$status" -eq 0 ]
  [ -d "input-cache" ]
}

@test "downloads publisher.jar when not present, with --yes" {
  # Mock curl to simulate download
  cat > ./curl <<'EOF'
#!/bin/bash
while [[ "$1" != '-o' && "$1" != '' ]]; do
  echo "arg is $1"
  shift
done
echo "JAR CONTENT" > "$2"  # simulate: curl -o file
EOF
  chmod +x ./curl

  PATH="$(pwd):$PATH" 
  run $SCRIPT_UNDER_TEST --yes
  [ "$status" -eq 0 ]
  [ -f "input-cache/publisher.jar" ] || [ -f "$(dirname "$PWD")/publisher.jar" ]
  rm -f _gen*.* _update*.* # remove the dummy scripts created with running this script 
}

@test "updates helper scripts with --yes (mocked curl)" {
  cat > ./curl <<'EOF'
#!/bin/bash
while [[ "$1" != '-o' && "$1" != '' ]]; do
  echo "arg is $1"
  shift
done
echo "file should be $2"
touch $(basename "$2")  # simulate download
EOF
  chmod +x ./curl

  PATH="$(pwd):$PATH"
  source $SCRIPT_UNDER_TEST
  run update_script "https://example.com/testscript"

  [ -f "testscript" ]
}
