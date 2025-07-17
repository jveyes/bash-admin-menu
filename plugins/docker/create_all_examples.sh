#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

print_box \
    "$(print_colored "$TITLE_COLOR" "🐳 Docker Examples Setup")" \
    "$(print_colored "$INFO_COLOR" "Creating examples for testing all Docker management features")"

echo
print_box "$(print_colored "$INFO_COLOR" "Step 1: Creating example volumes...")"
bash "$SCRIPT_DIR/create_example_volumes.sh"

echo
print_box "$(print_colored "$INFO_COLOR" "Step 2: Pulling example images...")"
bash "$SCRIPT_DIR/create_example_images.sh"

echo
print_box "$(print_colored "$INFO_COLOR" "Step 3: Creating basic containers...")"
bash "$SCRIPT_DIR/create_example_containers.sh"

echo
print_box "$(print_colored "$INFO_COLOR" "Step 4: Creating containers with volumes...")"
bash "$SCRIPT_DIR/create_example_containers_with_volumes.sh"

echo
print_box \
    "$(print_colored "$SUCCESS_COLOR" "✅ All examples created successfully!")" \
    "$(print_colored "$INFO_COLOR" "You can now test all Docker management features:")" \
    "$(print_colored "$MENU_COLOR" "• Container management (start, stop, remove, logs, exec, inspect)")" \
    "$(print_colored "$MENU_COLOR" "• Image management (list, remove, pull, inspect)")" \
    "$(print_colored "$MENU_COLOR" "• Volume management (list, remove, create, inspect)")" 