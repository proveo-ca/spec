#!/usr/bin/env bash
#
# spec
#
# Description:
#   Host executor for the Spec Build tool.
#   Mounts the target directory into a Docker container to generate diagrams.
#
# Usage:
#   spec [target_dir] [-v|--verbose] [-d|--dry-run] [--debug]
#

set -o errexit
set -o nounset
set -o pipefail

readonly IMAGE_NAME="proveo/spec:latest"

usage() {
  cat <<EOF
Usage: $(basename "${0}") [target_dir] [options]

Arguments:
  target_dir       Directory to scan (default: current directory)

Options:
  -v, --verbose    Enable verbose mode
  -d, --dry-run    Print the docker command without executing
  --debug          Enable shell debugging (set -x)
  -h, --help       Show this help message
EOF
}

check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "Error: docker command not found." >&2
    return 1
  fi

  if ! docker info &> /dev/null; then
    echo "Error: docker daemon is not running." >&2
    return 1
  fi
  return 0
}

main() {
  local target_dir="$(pwd)"
  local verbose=0
  local dry_run=0
  local debug_mode=0

  while [[ $# -gt 0 ]]; do
    case "${1}" in
      -v|--verbose) verbose=1; shift ;;
      -d|--dry-run) dry_run=1; shift ;;
      --debug) debug_mode=1; shift ;;
      -h|--help) usage; exit 0 ;;
      -*) echo "Unknown option: ${1}" >&2; usage; exit 1 ;;
      *)
        if [[ -d "${1}" ]]; then
          target_dir="$(cd "${1}" && pwd)"
        else
          echo "Error: Directory '${1}' not found." >&2
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [[ "${debug_mode}" -eq 1 ]]; then set -x; fi
  if ! check_docker; then exit 1; fi

  local cmd=(docker run --rm -v "${target_dir}:/data" "${IMAGE_NAME}")

  if [[ "${verbose}" -eq 1 ]]; then cmd+=("--verbose"); fi

  if [[ "${dry_run}" -eq 1 ]]; then
    echo "Dry Run: ${cmd[*]}"
  else
    if [[ "${verbose}" -eq 1 ]]; then echo "Running in: ${target_dir}"; fi
    "${cmd[@]}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
