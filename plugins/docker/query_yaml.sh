#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

yaml_file=$(select_yaml_file) || exit 1

yq --version &>/dev/null
if [ $? -ne 0 ]; then
    print_box "$(print_colored "$ERROR_COLOR" "Querying YAML requires yq. Please install yq.")"
    exit 1
fi

echo
read -p "Enter yq query (e.g., .services): " yq_query

result=$(yq eval "$yq_query" "$yaml_file" 2>&1)
if [ $? -eq 0 ]; then
    print_box "$(print_colored "$INFO_COLOR" "Query result:")" "$result"
else
    print_box "$(print_colored "$ERROR_COLOR" "Query failed:")" "$result"
fi 