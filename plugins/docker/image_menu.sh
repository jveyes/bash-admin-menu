#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

show_image_menu() {
    clear
    print_box \
        "$(print_colored "$TITLE_COLOR" "Docker Image Management")" \
        "$(print_colored "$INFO_COLOR" "Manage your Docker images")"
    echo
    echo "1. 🗂️  List Images"
    echo "2. 🗑️  Remove Image"
    echo "3. ⬇️  Pull Image"
    echo "4. 🔍 Inspect Image"
    echo "5. 🏷️  Tag Image"
    echo "6. ✏️  Rename Image"
    echo "7. 🔨 Build Image"
    echo "8. 📤 Export Image"
    echo "9. 📥 Import Image"
    echo
    echo "q. 🔙 Back"
    echo
}

while true; do
    show_image_menu
    read -p "Select an option: " choice
    case $choice in
        1) bash "$SCRIPT_DIR/list_images.sh"; read -p "Press Enter to continue...";;
        2) bash "$SCRIPT_DIR/remove_image.sh"; read -p "Press Enter to continue...";;
        3) bash "$SCRIPT_DIR/pull_image.sh"; read -p "Press Enter to continue...";;
        4) bash "$SCRIPT_DIR/inspect_image.sh"; read -p "Press Enter to continue...";;
        5) bash "$SCRIPT_DIR/tag_image.sh"; read -p "Press Enter to continue...";;
        6) bash "$SCRIPT_DIR/rename_image.sh"; read -p "Press Enter to continue...";;
        7) bash "$SCRIPT_DIR/build_image.sh"; read -p "Press Enter to continue...";;
        8) bash "$SCRIPT_DIR/export_image.sh"; read -p "Press Enter to continue...";;
        9) bash "$SCRIPT_DIR/import_image.sh"; read -p "Press Enter to continue...";;
        q|Q) break;;
        *) print_colored "$ERROR_COLOR" "❌ Invalid option!"; sleep 1;;
    esac
done 