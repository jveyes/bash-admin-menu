#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

echo
read -p "Convert (1) YAML to JSON or (2) JSON to YAML? [1/2]: " direction
if [ "$direction" = "1" ]; then
    yaml_file=$(select_yaml_file) || exit 1
    yq --version &>/dev/null
    if [ $? -eq 0 ]; then
        result=$(yq -o=json . "$yaml_file" 2>&1)
        status=$?
    else
        result=$(python3 -c 'import sys, yaml, json; json.dump(yaml.safe_load(open(sys.argv[1])), sys.stdout, indent=2)' "$yaml_file" 2>&1)
        status=$?
    fi
    if [ $status -eq 0 ]; then
        print_box "$(print_colored "$SUCCESS_COLOR" "YAML to JSON:")" "$result"
    else
        print_box "$(print_colored "$ERROR_COLOR" "Conversion failed:")" "$result"
    fi
elif [ "$direction" = "2" ]; then
    read -p "Enter path to JSON file: " json_file
    if [ ! -f "$json_file" ]; then
        print_box "$(print_colored "$ERROR_COLOR" "File not found: $json_file")"
        exit 1
    fi
    yq --version &>/dev/null
    if [ $? -eq 0 ]; then
        result=$(yq -P . "$json_file" 2>&1)
        status=$?
    else
        result=$(python3 -c 'import sys, yaml, json; yaml.safe_dump(json.load(open(sys.argv[1])), sys.stdout, default_flow_style=False)' "$json_file" 2>&1)
        status=$?
    fi
    if [ $status -eq 0 ]; then
        print_box "$(print_colored "$SUCCESS_COLOR" "JSON to YAML:")" "$result"
    else
        print_box "$(print_colored "$ERROR_COLOR" "Conversion failed:")" "$result"
    fi
else
    print_box "$(print_colored "$ERROR_COLOR" "Invalid selection.")"
fi 