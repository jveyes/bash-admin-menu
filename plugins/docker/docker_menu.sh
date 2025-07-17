#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

show_docker_menu() {
    clear
    print_box \
        "$(print_colored "$TITLE_COLOR" "Docker Container Manager")" \
        "$(print_colored "$INFO_COLOR" "Manage your Docker containers easily")"
    echo
    echo "1. 📋 List Containers"
    echo "2. ▶️  Start Container"
    echo "3. ⏹️  Stop Container"
    echo "4. 🗑️  Remove Container"
    echo "5. 📄 View Logs"
    echo "6. 🖥️  Exec Shell"
    echo "7. 🔍 Inspect Container"
    echo "8. 🖼️  Image Management"
    echo "9. 📦 Volume Management"
    echo "10. 📄 YAML Management"
    echo
    echo "q. ❌ Quit"
    echo
}

while true; do
    show_docker_menu
    read -p "Select an option: " choice
    case $choice in
        1) bash "$SCRIPT_DIR/list_containers.sh"; read -p "Press Enter to continue...";;
        2) bash "$SCRIPT_DIR/start_container.sh"; read -p "Press Enter to continue...";;
        3) bash "$SCRIPT_DIR/stop_container.sh"; read -p "Press Enter to continue...";;
        4) bash "$SCRIPT_DIR/remove_container.sh"; read -p "Press Enter to continue...";;
        5) bash "$SCRIPT_DIR/view_logs.sh"; read -p "Press Enter to continue...";;
        6) bash "$SCRIPT_DIR/exec_shell.sh"; read -p "Press Enter to continue...";;
        7) bash "$SCRIPT_DIR/inspect_container.sh"; read -p "Press Enter to continue...";;
        8) bash "$SCRIPT_DIR/image_menu.sh";;
        9) bash "$SCRIPT_DIR/volume_menu.sh";;
        10) bash "$SCRIPT_DIR/yaml_menu.sh";;
        q|Q) break;;
        *) print_colored "$ERROR_COLOR" "❌ Invalid option!"; sleep 1;;
    esac
done 