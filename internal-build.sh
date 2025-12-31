#!/usr/bin/env bash
# internal-build.sh
# Scans /data for .puml files and generates SVGs.

set -o errexit
set -o nounset
set -o pipefail

readonly PLANTUML_JAR="/opt/plantuml.jar"
readonly EXCLUDE_DIRS=("dist" "build" ".git" "node_modules")

generate_svg() {
  local file="${1}"
  echo "Processing: ${file}"
  java -jar "${PLANTUML_JAR}" -tsvg "${file}"
}

main() {
  local verbose=0
  while [[ $# -gt 0 ]]; do
    case "${1}" in
      -v|--verbose) verbose=1; shift ;;
      *) shift ;;
    esac
  done

  if [[ "${verbose}" -eq 1 ]]; then set -x; fi

  local find_cmd=(find . -type d \( -name "${EXCLUDE_DIRS[0]}")
  for ((i=1; i<${#EXCLUDE_DIRS[@]}; i++)); do
    find_cmd+=(-o -name "${EXCLUDE_DIRS[i]}")
  done
  find_cmd+=( \) -prune -o -type f -name "*.puml" -print )

  local puml_files=()
  while IFS= read -r file; do
    puml_files+=("${file}")
  done < <("${find_cmd[@]}")

  if [[ ${#puml_files[@]} -eq 0 ]]; then
    echo "No .puml files found in $(pwd)"
    exit 0
  fi

  for file in "${puml_files[@]}"; do
    generate_svg "${file}"
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
