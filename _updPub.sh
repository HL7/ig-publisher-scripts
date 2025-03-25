#!/bin/bash
#
# Script to download/update the IG publisher jar
# and some helper scripts
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pubsource=https://github.com/HL7/fhir-ig-publisher/releases/latest/download
publisher_jar=publisher.jar
dlurl="${pubsource}/${publisher_jar}"

input_cache_path="$(pwd)/input-cache"

scriptdlroot=https://raw.githubusercontent.com/HL7/ig-publisher-scripts/main
update_bat_url="${scriptdlroot}/_updatePublisher.bat"
gen_bat_url="${scriptdlroot}/_genonce.bat"
gencont_bat_url="${scriptdlroot}/_gencontinuous.bat"
gencont_sh_url="${scriptdlroot}/_gencontinuous.sh"
gen_sh_url="${scriptdlroot}/_genonce.sh"
update_sh_url="${scriptdlroot}/_updatePublisher.sh"

# Default values
FORCE=false
skipPrompts=false

ynprompt="(enter 'y' or 'Y' to continue, any other key to cancel)"

# Check if curl is available
check_for_curl() {
  if ! command -v curl >/dev/null 2>&1 && ! type curl >/dev/null 2>&1; then
      echo "❌ ERROR: 'curl' is required to download the latest IG Publisher."
      echo "👉 Please install 'curl' and try again."
      echo "   - macOS (Homebrew): brew install curl"
      echo "   - Ubuntu/Debian:    sudo apt install curl"
      echo "   - RedHat/Fedora:    sudo dnf install curl"
      echo "   - Windows (WSL):    sudo apt install curl"
      exit 1
  fi
}

# Show help information

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -f, --force        Force the operation, may override warnings or checks.
  -y, --yes          Automatically answer 'yes' to prompts. Implies --force.
  -s, --skip         Skip prompts and proceed. Same as --yes.
  -h, --help         Display this help message and exit.

Examples:
  $(basename "$0") --force
  $(basename "$0") -y

EOF
}

# Download using default curl options

get_file() {
  url=$1
  output=${2:-'/tmp/dummy'}
  # curl --fail --silent --show-error --location --retry 3 --max-time 30 ....
  curl -fsSL --retry 3 --max-time 30 "${url}" -o "$output"
  result=$?
  return $result
}

# update the script

update_script() {
  local url=$1
  local filename=${url##*/}

  get_file $url /tmp/${filename}.new
  result=$?
  if [[ $result -ne 0 ]]; then
    return $result
  fi
  cp /tmp/${filename}.new ${filename}
  rm /tmp/${filename}.new
}

# Check connection to terminology server

check_network() {
  echo "🌐 Checking internet connection to tx.fhir.org..."

  if ! get_file https://tx.fhir.org /tmp/dummy > /dev/null 2>&1 ; then
      echo "❌ Offline or the terminology server is unreachable."
      echo "🚫 Unable to update. Please check your internet connection or try again later."
      exit 1
  fi
  return 0
}

# get parameters

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=true
            ;;
        -y|--yes|-s|--skip)
            skipPrompts=true
            FORCE=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Use --help to see valid options."
            exit 1
            ;;
    esac
    shift
done

update_publisher() {
  # Check for existence of input_cache

  if [[ ! -d "${input_cache_path}" ]] ; then
    if [[ $FORCE != true ]]; then
      echo "${input_cache_path} does not exist"
      message="create it? ${ynprompt} "
      read -r -p "$message" response
    else
      response=y
    fi
  fi

  if [[ $response =~ ^[yY].*$ ]] ; then
    mkdir ./input-cache
  fi

  # Determine the location of the IG Publisher jar and decide on updating

  publisher="${input_cache_path}/${publisher_jar}"
  jarlocationname="Input Cache"
  upgrade=true

  if [[ -f "${publisher}" ]]; then
    echo "IG Publisher FOUND in input-cache"
    jarlocation="${publisher}"
  else
    publisher="$( dirname ${PWD})/${publisher_jar}"
    echo "publisher = ${publisher}"
    if [[ -f "${publisher}" ]]; then
      echo "IG Publisher FOUND in parent folder"
      jarlocation="${publisher}"
      jarlocationname="Parent Folder"
    else
      echo "IG Publisher NOT FOUND in input-cache or parent folder"
      jarlocation="${input_cache_path}/${publisher_jar}"
      upgrade=false
    fi
  fi

  if [[ $skipPrompts == false ]]; then

    if [[ $upgrade == true ]]; then
      message="Overwrite $jarlocation? ${ynprompt} "
    else
      echo Will place publisher jar here: "$jarlocation"
      message="Ok? ${ynprompt} "
    fi
    read -r -p "$message" response
  else
    response=y
  fi

  if [[ $skipPrompts == true ]] || [[ $response =~ ^[yY].*$ ]]; then

    echo "Downloading most recent publisher to ${jarlocationname} - it's ~100 MB, so this may take a bit"
    get_file "${dlurl}" "${jarlocation}"
  else
    echo "Cancelled publisher update"
  fi
}

#  Update the scripts

update_helper_scripts() {
  if [[ $skipPrompts != true ]]; then
      message="Update scripts? ${ynprompt} "
      read -r -p "$message" response
    fi

  if [[ $skipPrompts == true ]] || [[ $response =~ ^[yY].*$ ]]; then
    echo "Downloading most recent scripts"

    update_script $update_bat_url 
    update_script $gen_bat_url 
    update_script $gencont_bat_url 
    update_script $gencont_sh_url 
    update_script $gen_sh_url 
    update_script $update_sh_url 
  fi
}

main() {
  # Main script logic here

  check_for_curl
  check_network
  update_publisher
  update_helper_scripts
}

# Only run main if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi