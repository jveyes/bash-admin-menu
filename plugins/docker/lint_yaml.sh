#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

yaml_file=$(select_yaml_file) || exit 1

yamllint --version &>/dev/null
if [ $? -ne 0 ]; then
    print_box "$(print_colored "$ERROR_COLOR" "Linting YAML requires yamllint. Please install yamllint.")"
    exit 1
fi

result=$(yamllint "$yaml_file" 2>&1)
if [ $? -eq 0 ]; then
    print_box "$(print_colored "$SUCCESS_COLOR" "YAML lint passed: $yaml_file")"
else
    print_box "$(print_colored "$ERROR_COLOR" "YAML lint failed:")" "$result"
fi 