#!/usr/bin/env bash
#
# install.sh
#
# Description:
#   Installs the spec executable to /usr/local/bin.
#   Requires sudo permissions if /usr/local/bin is not writable.
#
# Usage:
#   ./install.sh [-v|--verbose] [--debug]
#

set -o errexit
set -o nounset
set -o pipefail

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
readonly SOURCE_FILE="spec-build.sh"
readonly DEST_DIR="/usr/local/bin"
readonly DEST_FILE="${DEST_DIR}/spec"
readonly IMAGE_NAME="proveo/spec:latest"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Description:
#   Prints usage information.
# Arguments:
#   None
# Outputs:
#   Writes usage to STDOUT.
usage() {
  cat <<EOF
Usage: $(basename "${0}") [options]

Options:
  -v, --verbose    Enable verbose output
  --debug          Enable shell debugging (set -x)
  -h, --help       Show this help message
EOF
}

# Description:
#   Main entry point.
# Arguments:
#   $@: Command line arguments
# Outputs:
#   Writes execution status to STDOUT/STDERR.
main() {
  local verbose=0
  local debug_mode=0

  while [[ $# -gt 0 ]]; do
    case "${1}" in
      -v|--verbose)
        verbose=1
        shift
        ;;
      --debug)
        debug_mode=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: ${1}" >&2
        usage
        exit 1
        ;;
    esac
  done

  if [[ "${debug_mode}" -eq 1 ]]; then
    set -x
  fi

  # 1. Build Docker Image
  echo "Building Docker image '${IMAGE_NAME}'..."
  if [[ "${verbose}" -eq 1 ]]; then
    docker build -t "${IMAGE_NAME}" .
  else
    docker build -t "${IMAGE_NAME}" . > /dev/null
  fi
  echo "Docker image built successfully."

  if [[ ! -f "${SOURCE_FILE}" ]]; then
    echo "Error: Source file '${SOURCE_FILE}' not found in current directory." >&2
    exit 1
  fi

  if [[ "${verbose}" -eq 1 ]]; then
    echo "Installing ${SOURCE_FILE} to ${DEST_FILE}..."
  fi

  # Create a sanitized temporary file (remove CRLF)
  local temp_file
  temp_file=$(mktemp)
  tr -d '\r' < "${SOURCE_FILE}" > "${temp_file}"

  # Check permissions
  if [[ -w "${DEST_DIR}" ]]; then
    cp "${temp_file}" "${DEST_FILE}"
    chmod +x "${DEST_FILE}"
  else
    echo "Need elevated permissions to write to ${DEST_DIR}."
    sudo cp "${temp_file}" "${DEST_FILE}"
    sudo chmod +x "${DEST_FILE}"
  fi

  rm "${temp_file}"

  echo "All set."
  echo "Run 'spec --help' to get started."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
