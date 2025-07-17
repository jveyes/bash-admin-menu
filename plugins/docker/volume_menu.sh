#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

show_volume_menu() {
    clear
    print_box \
        "$(print_colored "$TITLE_COLOR" "Docker Volume Management")" \
        "$(print_colored "$INFO_COLOR" "Manage your Docker volumes")"
    echo
    echo "1. 🗂️  List Volumes"
    echo "2. 🗑️  Remove Volume"
    echo "3. ➕ Create Volume"
    echo "4. 🔍 Inspect Volume"
    echo
    echo "q. 🔙 Back"
    echo
}

while true; do
    show_volume_menu
    read -p "Select an option: " choice
    case $choice in
        1) bash "$SCRIPT_DIR/list_volumes.sh"; read -p "Press Enter to continue...";;
        2) bash "$SCRIPT_DIR/remove_volume.sh"; read -p "Press Enter to continue...";;
        3) bash "$SCRIPT_DIR/create_volume.sh"; read -p "Press Enter to continue...";;
        4) bash "$SCRIPT_DIR/inspect_volume.sh"; read -p "Press Enter to continue...";;
        q|Q) break;;
        *) print_colored "$ERROR_COLOR" "❌ Invalid option!"; sleep 1;;
    esac
done 