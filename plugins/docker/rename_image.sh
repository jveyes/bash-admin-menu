#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

images=()
while IFS='|' read -r repo tag id; do
    images+=("$repo|$tag|$id")
done < <(docker images --format "{{.Repository}}|{{.Tag}}|{{.ID}}")

if [ ${#images[@]} -eq 0 ]; then
    print_box "$(print_colored "$WARNING_COLOR" "No images to rename.")"
    exit 0
fi

max_repo=9; max_tag=3
for entry in "${images[@]}"; do
    IFS='|' read -r repo tag id <<< "$entry"
    [ ${#repo} -gt $max_repo ] && max_repo=${#repo}
    [ ${#tag} -gt $max_tag ] && max_tag=${#tag}
done

rows=()
for i in "${!images[@]}"; do
    IFS='|' read -r repo tag id <<< "${images[$i]}"
    rows+=("$(print_colored "$INFO_COLOR" "$(printf '%2d. %-*s:%-*s' $((i+1)) $max_repo "$repo" $max_tag "$tag")")")
done
print_box "$(print_colored "$MENU_COLOR" "Available images:")" "${rows[@]}"

echo
read -p "Select an image to rename [1-${#images[@]}]: " idx
if [[ $idx =~ ^[0-9]+$ ]] && [ $idx -ge 1 ] && [ $idx -le ${#images[@]} ]; then
    IFS='|' read -r repo tag id <<< "${images[$((idx-1))]}"
    echo
    read -p "Enter new repository name: " new_repo
    
    if [ -n "$new_repo" ]; then
        if docker tag "$repo:$tag" "$new_repo:$tag"; then
            print_box "$(print_colored "$SUCCESS_COLOR" "Successfully renamed $repo:$tag to $new_repo:$tag")"
            print_box "$(print_colored "$INFO_COLOR" "Note: Original image still exists. Use 'Remove Image' to delete the old one.")"
        else
            print_box "$(print_colored "$ERROR_COLOR" "Failed to rename image")"
        fi
    else
        print_box "$(print_colored "$ERROR_COLOR" "Repository name is required.")"
    fi
else
    print_box "$(print_colored "$ERROR_COLOR" "Invalid selection.")"
fi 