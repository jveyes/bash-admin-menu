#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

clear
if [ -n "$1" ]; then
    yaml_file="$1"
else
    yaml_file=$(select_yaml_file) || exit 1
fi

yamllint --version &>/dev/null
if [ $? -eq 0 ]; then
    result=$(yamllint "$yaml_file" 2>&1)
    clear
    if [ $? -eq 0 ]; then
        # Print the title in its own frame
        print_box "$(print_colored "$TITLE_COLOR" "YAML Validation Result")"
        # Print the result in a separate frame
        print_box "$(print_colored "$SUCCESS_COLOR" "YAML is valid: $yaml_file")"
    else
        print_box "$(print_colored "$TITLE_COLOR" "YAML Validation Result")"
        print_box "$(print_colored "$ERROR_COLOR" "YAML validation failed:")" "$result"
    fi
else
    # Fallback: Python validation
    python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$yaml_file" 2>tmp_yaml_err
    clear
    if [ $? -eq 0 ]; then
        print_box "$(print_colored "$TITLE_COLOR" "YAML Validation Result")"
        print_box "$(print_colored "$SUCCESS_COLOR" "YAML is valid: $yaml_file")"
    else
        err=$(cat tmp_yaml_err)
        print_box "$(print_colored "$TITLE_COLOR" "YAML Validation Result")"
        print_box "$(print_colored "$ERROR_COLOR" "YAML validation failed:")" "$err"
    fi
    rm -f tmp_yaml_err
fi 