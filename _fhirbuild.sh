#!/bin/bash

# _fhirbuild.sh: builds FHIR IGs with the IG Publisher, on Linux and macOS. One copy per computer, not a copy in each IG.
#   _fhirbuild.sh install    associate .fhirbuild and .fhirbuildonce files with this script, where it is
#                            (current user, no admin rights). Run again after moving the script.
#   _fhirbuild.sh uninstall  remove these associations
# Opening a .fhirbuild file (e.g. an empty _ig.fhirbuild in the IG folder) runs this script in a terminal on the
# folder of that file, with the menu; a .fhirbuildonce file runs the build directly.
# The first argument can also be any file. Without a file, it runs on the current folder.
# Options: update, build, nosushi, notx, jekyll, clean, exit; other arguments are passed to the publisher.

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_path="${script_dir}/$(basename "${BASH_SOURCE[0]}")"

# Names used for the file associations
app_name="FHIR IG build"
desktop_id="org.hl7.fhir.igbuild"
mac_app="$HOME/Applications/${app_name}.app"
lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"


function install_linux() {
  local data="${XDG_DATA_HOME:-$HOME/.local/share}"
  mkdir -p "$data/mime/packages" "$data/applications"
  cat > "$data/mime/packages/${desktop_id}.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-fhirbuild">
    <comment>FHIR IG build</comment>
    <glob pattern="*.fhirbuild"/>
  </mime-type>
  <mime-type type="application/x-fhirbuildonce">
    <comment>FHIR IG build (once)</comment>
    <glob pattern="*.fhirbuildonce"/>
  </mime-type>
</mime-info>
EOF
  # Quoting rules of desktop entries: escape \ " ` $ inside the double quotes
  local exec_path
  exec_path=$(printf '%s' "$script_path" | sed -e 's/[\\"`$]/\\&/g')
  cat > "$data/applications/${desktop_id}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${app_name}
Comment=Runs the FHIR IG Publisher on the folder of the file
Exec="${exec_path}" %f
Terminal=true
NoDisplay=true
MimeType=application/x-fhirbuild;application/x-fhirbuildonce;
EOF
  update-mime-database "$data/mime" > /dev/null 2>&1 || echo "Warning: update-mime-database failed or is not installed"
  if command -v update-desktop-database > /dev/null 2>&1; then
    update-desktop-database "$data/applications" > /dev/null 2>&1 || true
  fi
  if command -v xdg-mime > /dev/null 2>&1; then
    xdg-mime default "${desktop_id}.desktop" application/x-fhirbuild application/x-fhirbuildonce
  elif command -v gio > /dev/null 2>&1; then
    gio mime application/x-fhirbuild "${desktop_id}.desktop" > /dev/null
    gio mime application/x-fhirbuildonce "${desktop_id}.desktop" > /dev/null
  else
    echo "Warning: neither xdg-mime nor gio is installed, so ${app_name} may not be the default for these files"
  fi
}

function uninstall_linux() {
  local data="${XDG_DATA_HOME:-$HOME/.local/share}"
  local config="${XDG_CONFIG_HOME:-$HOME/.config}"
  rm -f "$data/mime/packages/${desktop_id}.xml" "$data/applications/${desktop_id}.desktop"
  update-mime-database "$data/mime" > /dev/null 2>&1 || true
  if command -v update-desktop-database > /dev/null 2>&1; then
    update-desktop-database "$data/applications" > /dev/null 2>&1 || true
  fi
  # Default set by xdg-mime
  for list in "$config/mimeapps.list" "$data/applications/mimeapps.list"; do
    if [ -f "$list" ]; then
      sed -i -e '/^application\/x-fhirbuild\(once\)\?=/d' "$list"
    fi
  done
}

# macOS sends opened files to an app, not to a script: a small AppleScript app runs this script in Terminal
function install_mac() {
  local tmp script_literal
  tmp="$(mktemp -d)"
  # AppleScript string literal: escape \ and "
  script_literal=$(printf '%s' "$script_path" | sed -e 's/[\\"]/\\&/g')
  cat > "$tmp/app.applescript" <<EOF
on open theFiles
  repeat with f in theFiles
    tell application "Terminal"
      activate
      do script (quoted form of "${script_literal}") & " " & (quoted form of POSIX path of f)
    end tell
  end repeat
end open

on run
  display dialog "Open a .fhirbuild or .fhirbuildonce file to build the IG in its folder." buttons {"OK"} default button 1
end run
EOF
  rm -rf "$mac_app"
  mkdir -p "$(dirname "$mac_app")"
  osacompile -o "$mac_app" "$tmp/app.applescript"
  rm -rf "$tmp"

  local plist="$mac_app/Contents/Info.plist"
  plutil -replace CFBundleIdentifier -string "$desktop_id" "$plist"
  plutil -replace UTExportedTypeDeclarations -json '[
    {"UTTypeIdentifier": "org.hl7.fhir.fhirbuild", "UTTypeDescription": "FHIR IG build",
     "UTTypeConformsTo": ["public.data"], "UTTypeTagSpecification": {"public.filename-extension": ["fhirbuild"]}},
    {"UTTypeIdentifier": "org.hl7.fhir.fhirbuildonce", "UTTypeDescription": "FHIR IG build (once)",
     "UTTypeConformsTo": ["public.data"], "UTTypeTagSpecification": {"public.filename-extension": ["fhirbuildonce"]}}
  ]' "$plist"
  plutil -replace CFBundleDocumentTypes -json '[
    {"CFBundleTypeName": "FHIR IG build", "CFBundleTypeRole": "Viewer", "LSHandlerRank": "Owner",
     "LSItemContentTypes": ["org.hl7.fhir.fhirbuild", "org.hl7.fhir.fhirbuildonce"]}
  ]' "$plist"
  # Changing Info.plist invalidates the signature that osacompile made
  codesign --force --sign - "$mac_app" > /dev/null 2>&1 || true
  "$lsregister" -f "$mac_app"
}

function uninstall_mac() {
  if [ -d "$mac_app" ]; then
    "$lsregister" -u "$mac_app" > /dev/null 2>&1 || true
    rm -rf "$mac_app"
  fi
}

function install_associations() {
  chmod +x "$script_path"
  case "$(uname -s)" in
    Darwin) install_mac ;;
    Linux)  install_linux ;;
    *) echo "File associations are only supported on Linux and macOS."; exit 1 ;;
  esac
  echo "Opening a .fhirbuild file now runs ${script_path} in a terminal, in the folder that contains the file."
  echo "Opening a .fhirbuildonce file runs the build directly, without the menu."
  echo "If you move this script, run install again."
}

function uninstall_associations() {
  case "$(uname -s)" in
    Darwin) uninstall_mac ;;
    Linux)  uninstall_linux ;;
    *) echo "File associations are only supported on Linux and macOS."; exit 1 ;;
  esac
  echo "Removed the .fhirbuild and .fhirbuildonce associations. This script and the publisher are not touched."
}

case "${1:-}" in
  install)   install_associations; exit 0 ;;
  uninstall) uninstall_associations; exit 0 ;;
esac

# A file as first argument: run on its folder. A .fhirbuildonce file means "build", as on Windows.
if [ $# -gt 0 ] && [ -f "$1" ]; then
  opened_file="$1"
  shift
  cd "$(dirname "$opened_file")"
  if [[ "$opened_file" == *.fhirbuildonce ]]; then
    set -- build "$@"
  fi
  # Keep the terminal window open at the end, also after an error
  if [ -t 0 ]; then
    trap 'echo; read -r -p "Press Enter to close..." _' EXIT
  fi
fi

# Variables
dlurl="https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar"
publisher_jar="publisher.jar"
input_cache_path="$(pwd)/input-cache/"
publisher_home="${FHIR_PUBLISHER_HOME:-$HOME/.fhir/tools/publisher}"
skipPrompts=false
upper_path="../"
# TEMPORARY: updates from the no-local-scripts branch until it is merged; then back to main
scriptdlroot="https://raw.githubusercontent.com/HL7/ig-publisher-scripts/no-local-scripts"
fhirbuild_sh_url="${scriptdlroot}/_fhirbuild.sh"
fhirbuild_bat_url="${scriptdlroot}/_fhirbuild.bat"

function check_jar_location() {
  if [ -f "${input_cache_path}${publisher_jar}" ]; then
    jar_location="${input_cache_path}${publisher_jar}"
    echo "Found publisher.jar in input-cache"
  elif [ -f "${upper_path}${publisher_jar}" ]; then
    jar_location="${upper_path}${publisher_jar}"
    echo "Found publisher.jar in parent folder"
  elif [ -f "${publisher_home}/${publisher_jar}" ]; then
    jar_location="${publisher_home}/${publisher_jar}"
    echo "Found publisher.jar in FHIR publisher home"
  else
    jar_location="not_found"
    echo "publisher.jar not found in input-cache, parent folder, or FHIR publisher home"
  fi
}

function check_internet_connection() {
  local target="tx.fhir.org"
  local reachable=false

  if command -v ping > /dev/null 2>&1; then
    if ping -c 1 -W 5 "$target" > /dev/null 2>&1 \
    || ping -c 1 -w 5 "$target" > /dev/null 2>&1; then
      reachable=true
    fi
  elif command -v curl > /dev/null 2>&1; then
    if curl --silent --max-time 5 --output /dev/null "https://$target"; then
      reachable=true
    fi
  else
    echo "WARNING: Neither ping nor curl available — assuming offline."
  fi

  if [ "$reachable" = "true" ]; then
    online=true
    echo "We're online and $target is available."
    latest_version=$(curl -s https://api.github.com/repos/HL7/fhir-ig-publisher/releases/latest | grep tag_name | cut -d'"' -f4)
  else
    online=false
    echo ""
    echo "⚠️  WARNING: Working offline — this is not the normal mode."
    echo "   Some features (e.g. terminology rendering) will not work."
    echo ""
  fi
}



function update_publisher() {
  # Same order as check_jar_location, so that the publisher that is checked is the one that is updated
  if [ -f "${input_cache_path}${publisher_jar}" ]; then
    update_location="${input_cache_path}${publisher_jar}"
    update_location_name="input-cache"
  elif [ -f "${upper_path}${publisher_jar}" ]; then
    update_location="$(pwd)/${upper_path}${publisher_jar}"
    update_location_name="parent folder"
  else
    update_location="${publisher_home}/${publisher_jar}"
    update_location_name="FHIR publisher home"
  fi
  echo "Publisher jar location: ${update_location}"
  if [ "$skipPrompts" = "true" ]; then
    confirm="Y"
  else
    read -p "Download or update publisher.jar? (Y/N): " confirm
  fi
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Downloading latest publisher.jar (~200 MB)..."
    mkdir -p "$(dirname "$update_location")"
    curl -L "$dlurl" -o "$update_location"
    echo "Publisher updated in ${update_location_name}"
  else
    echo "Skipped downloading publisher.jar"
  fi

  update_scripts_prompt
}


# Updates this script where it is, not in the IG folder
function update_scripts_prompt() {
  if [ "$skipPrompts" = "true" ]; then
    update_confirm="Y"
  else
    read -p "Update _fhirbuild.sh and _fhirbuild.bat? (Y/N): " update_confirm
  fi
  if [[ "$update_confirm" =~ ^[Yy]$ ]]; then
    update_script_file "$fhirbuild_sh_url" "$script_path"
    update_script_file "$fhirbuild_bat_url" "${script_dir}/_fhirbuild.bat"
  else
    echo "Skipped updating the scripts."
  fi
}

# Parameters: url, file. Downloads to a temporary file first, so a failed download keeps the file as it is.
# mv replaces the file, so this script can update itself while it runs.
function update_script_file() {
  echo "Updating $2..."
  if curl -fsSL "$1" -o "$2.new"; then
    chmod +x "$2.new"
    mv "$2.new" "$2"
  else
    rm -f "$2.new"
    echo "Could not download $1; $2 was not updated."
  fi
}


function run_publisher() {
  local extra_flags=("$@")
  if [ "$jar_location" != "not_found" ]; then
    echo "jar_location is: $jar_location"
    if [[ "$JAVA_TOOL_OPTIONS" != *"-Dfile.encoding=UTF-8"* ]]; then
      export JAVA_TOOL_OPTIONS+=" -Dfile.encoding=UTF-8"
    fi
    java $JAVA_OPTS -jar "$jar_location" -ig . "${extra_flags[@]}"
  else
    echo "IG Publisher NOT FOUND in input-cache, parent folder, or FHIR publisher home. Please run update. Aborting..."
  fi
}

function build_ig() {
  local args=()
  if [ "$online" = "false" ]; then
    args+=("-tx" "n/a")
  fi
  run_publisher "${args[@]}" "$@"
}

function build_nosushi() {
  run_publisher -no-sushi "$@"
}

function build_notx() {
  run_publisher -tx n/a "$@"
}

function build_continuous() {
  run_publisher -watch "$@"
}

function jekyll_build() {
  echo "Running Jekyll build..."
  jekyll build -s temp/pages -d output
}

function cleanup() {
  echo "Cleaning up temp directories..."
  if [ -f "${input_cache_path}${publisher_jar}" ]; then
    mv "${input_cache_path}${publisher_jar}" ./
    rm -rf "${input_cache_path}"*
    mkdir -p "$input_cache_path"
    mv "$publisher_jar" "$input_cache_path"
  fi
  rm -rf ./output ./template ./temp
  echo "Cleanup complete."
}

check_jar_location

# Handle command-line arguments
# Known first arguments select a menu option; anything else is passed through to the publisher
extraArgs=()
if [ $# -gt 0 ]; then
  case "$1" in
    update)  shift; extraArgs=("$@"); update_publisher; exit 0 ;;
    build)   shift; extraArgs=("$@"); check_internet_connection; build_ig "${extraArgs[@]}"; exit 0 ;;
    nosushi) shift; extraArgs=("$@"); check_internet_connection; build_nosushi "${extraArgs[@]}"; exit 0 ;;
    notx)    shift; extraArgs=("$@"); build_notx "${extraArgs[@]}"; exit 0 ;;
    jekyll)  jekyll_build; exit 0 ;;
    clean)   cleanup; exit 0 ;;
    exit)    exit 0 ;;
    *)
      # Unknown first arg - default to build, pass all args through
      extraArgs=("$@")
      run_publisher "${extraArgs[@]}"
      exit 0
      ;;
  esac
fi

# Interactive menu
check_internet_connection

# Compute default choice and reason
default_choice=2
default_reason="publisher is up to date"

if [ "$jar_location" = "not_found" ]; then
  default_choice=1
  default_reason="publisher not found"
elif [ "$online" = "false" ]; then
  default_choice=4
  default_reason="working offline"
elif [ -n "$latest_version" ]; then
  current_version=$(java -jar "$jar_location" -v 2>/dev/null | tr -d '\r')
  if [ "$current_version" != "$latest_version" ]; then
    default_choice=1
    default_reason="newer version available"
  fi
fi

echo "---------------------------------------------"
echo "Publisher: ${current_version:-unknown}; Latest: ${latest_version:-unknown}"
echo "Publisher location: $jar_location"
echo "Online: $online"
echo "---------------------------------------------"
echo
echo "Please select an option:"
echo "1) Download or update publisher"
echo "2) Build IG"
echo "3) Build IG without Sushi"
echo "4) Build IG without TX server"
echo "5) Jekyll build"
echo "6) Cleanup temp directories"
echo "7) Install: associate .fhirbuild and .fhirbuildonce files with this script"
echo "8) Uninstall: remove the .fhirbuild and .fhirbuildonce file associations"
echo "0) Exit"
echo

# Read with timeout, but default if nothing entered
echo -n "Choose an option [default: $default_choice - $default_reason]: "
read -t 5 choice || choice="$default_choice"
choice="${choice:-$default_choice}"
echo "You selected: $choice"

case "$choice" in
  1) update_publisher ;;
  2) build_ig ;;
  3) build_nosushi ;;
  4) build_notx ;;
  5) jekyll_build ;;
  6) cleanup ;;
  7) install_associations ;;
  8) uninstall_associations ;;
  0) exit 0 ;;
  *) echo "Invalid option." ;;
esac
