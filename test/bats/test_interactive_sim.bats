#!/usr/bin/env bats

setup() {
  rm -rf input-cache testscript publisher.jar
  mkdir -p test/mocks
  echo "Mock Content" > test/mocks/testscript.new
}

teardown() {
  rm -rf input-cache testscript publisher.jar curl test/mocks/testscript.new
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
echo "JAR CONTENT" > "$8"  # simulate: curl -o file
EOF
  chmod +x ./curl

  PATH="$(pwd):$PATH" 
  run $SCRIPT_UNDER_TEST --yes
  [ "$status" -eq 0 ]
  [ -f "input-cache/publisher.jar" ] || [ -f "$(basename "$PWD")/publisher.jar" ]
}

@test "updates helper scripts with --yes (mocked curl)" {
  cat > ./curl <<'EOF'
#!/bin/bash
touch /tmp/$(basename "$8").new  # simulate download
EOF
  chmod +x ./curl

  PATH="$(pwd):$PATH"
  source $SCRIPT_UNDER_TEST
  run update_script "https://example.com/testscript"

  [ -f "testscript" ]
}
