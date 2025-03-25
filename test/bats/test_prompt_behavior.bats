#!/usr/bin/env bats

setup() {
  rm -rf input-cache testscript publisher.jar curl
}

teardown() {
  rm -rf input-cache testscript publisher.jar curl 
}

@test "prompts answered manually: yes to create dir, no to update scripts" {
  # Ensure input-cache does NOT exist
  [ ! -d input-cache ]

  # Mock curl to pass terminology check but not actually download anything
  cat > ./curl <<'EOF'
#!/bin/bash
if [[ "$8" == *publisher.jar ]]; then
  echo "Pretend to download publisher.jar" > "$8"
else
  exit 0
fi
EOF
  chmod +x ./curl

  # Use a heredoc to simulate manual responses:
  # 1. y = create input-cache
  # 2. y = confirm download publisher
  # 3. n = skip script updates
  run bash $SCRIPT_UNDER_TEST <<EOF
y
y
n
EOF

  # Check that input-cache was created
  [ -d input-cache ]

  # Check that helper scripts were not updated
  [ ! -f "_updatePublisher.bat" ]
}

@test "prompts answered manually: no to create input-cache" {
  # Ensure input-cache does not exist
  [ ! -d input-cache ]

  # Mock curl to simulate successful tx.fhir.org ping
  cat > ./curl <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x ./curl

  # Simulate: 'n' when asked to create input-cache
  run bash $SCRIPT_UNDER_TEST <<EOF
n
EOF

  # Assert input-cache was NOT created
  [ ! -d input-cache ]
}

@test "prompts answered manually: yes to create dir, no to overwrite publisher jar" {
  # Prepare mock publisher.jar in parent directory
  mkdir -p tmp/test-ig
  cp $SCRIPT_UNDER_TEST tmp/test-ig/
  echo "EXISTING JAR" > tmp/publisher.jar

  # Mock curl to only simulate tx.fhir.org check
  cat > ./curl <<EOF
#!/bin/bash
if [[ "$1" == "https://tx.fhir.org" ]]; then
  exit 0
else
  echo "Should not reach download" >&2
  exit 1
fi
EOF

  chmod +x ./curl

  pushd tmp/test-ig > /dev/null

  PATH="$(pwd):$PATH" 
  run bash $SCRIPT_UNDER_TEST <<EOF
y
n
EOF

  # Assert input-cache created
  [ -d input-cache ]

  # Ensure publisher.jar was NOT overwritten
  run cat ../publisher.jar
  [ "$output" = "EXISTING JAR" ]

  popd > /dev/null
}

@test "prompts: skip publisher.jar update, but download helper scripts" {
  rm -f _updatePublisher.sh _genonce.sh
  rm -rf input-cache

  # Mock curl to:
  # 1. Simulate tx.fhir.org check
  # 2. Block publisher.jar download
  # 3. Allow downloading helper scripts

  cat > ./curl <<'EOF'
#!/bin/bash
if [[ "$1" == "https://tx.fhir.org" ]]; then
  exit 0
elif [[ "$8" =~ publisher\.jar ]]; then
  echo "Prevent jar download" >&2
  exit 1
else
  # Simulate helper script download
  echo "#!/bin/bash" > "$8"
  echo "# downloaded mock helper script" >> "$8"
  exit 0
fi
EOF
  chmod +x ./curl

  # Simulate:
  # 1. y → create input-cache
  # 2. n → skip publisher.jar
  # 3. y → update scripts
  run bash $SCRIPT_UNDER_TEST <<EOF
y
n
y
EOF

  [ -d input-cache ]
  [ ! -f "input-cache/publisher.jar" ]
  [ -f "_updatePublisher.sh" ]
  [ -f "_genonce.sh" ]

}
