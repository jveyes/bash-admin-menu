#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

images=()
while IFS='|' read -r repo tag id size; do
    images+=("$repo|$tag|$id|$size")
done < <(docker images --format "{{.Repository}}|{{.Tag}}|{{.ID}}|{{.Size}}")

if [ ${#images[@]} -eq 0 ]; then
    print_box "$(print_colored "$WARNING_COLOR" "No images found.")"
    exit 0
fi

max_repo=9; max_tag=3; max_id=7; max_size=4
for entry in "${images[@]}"; do
    IFS='|' read -r repo tag id size <<< "$entry"
    [ ${#repo} -gt $max_repo ] && max_repo=${#repo}
    [ ${#tag} -gt $max_tag ] && max_tag=${#tag}
    [ ${#id} -gt $max_id ] && max_id=${#id}
    [ ${#size} -gt $max_size ] && max_size=${#size}
done

header="$(print_colored "$MENU_COLOR" "$(printf '%-*s | %-*s | %-*s | %-*s' $max_repo 'Repository' $max_tag 'Tag' $max_id 'ImageID' $max_size 'Size')")"
rows=()
for entry in "${images[@]}"; do
    IFS='|' read -r repo tag id size <<< "$entry"
    rows+=("$(print_colored "$INFO_COLOR" "$(printf '%-*s' $max_repo "$repo")") | $(print_colored "$SUCCESS_COLOR" "$(printf '%-*s' $max_tag "$tag")") | $(print_colored "$MENU_COLOR" "$(printf '%-*s' $max_id "$id")") | $(print_colored "$INFO_COLOR" "$(printf '%-*s' $max_size "$size")")")
done

print_box "$header" "${rows[@]}" 