#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared SSH utility functions and variables
source "$SCRIPT_DIR/ssh_utils.sh"

# Function to display the Remote Tools menu
show_remote_tools_menu() {
    clear  # Clear the terminal screen
    # Print a styled box with the menu title and subtitle
    print_box \
        "$(print_colored "$TITLE_COLOR" "Remote Tools")" \
        "$(print_colored "$INFO_COLOR" "Basic remote server operations")"
    echo
    # Print menu options with emojis
    echo "1. 📡 Ping port 22 (SSH)"
    echo "2. 💾 Check disk, RAM, and CPU usage"
    echo "3. 📤 Secure file copy (scp/rsync)"
    echo "4. 👥 Active sessions and connections"
    echo "5. 🖥️  System version info"
    echo
    echo "q. ⬅️  Return to SSH Menu"
    echo
}

# Main loop: show the menu and handle user input
while true; do
    show_remote_tools_menu  # Display the menu
    read -p "Select an option: " choice  # Prompt user for input
    log_info "Remote Tools Menu" "User selected option: $choice"
    case $choice in
        1) "$SCRIPT_DIR/remote_tools/ping_port22.sh" ;;         # Ping port 22
        2) "$SCRIPT_DIR/remote_tools/check_usage.sh" ;;         # Disk/RAM/CPU usage
        3) "$SCRIPT_DIR/remote_tools/secure_copy.sh" ;;         # Secure file copy
        4) "$SCRIPT_DIR/remote_tools/active_sessions.sh" ;;     # Active sessions/connections
        5) "$SCRIPT_DIR/remote_tools/system_info.sh" ;;         # System version info
        q|Q) break ;;                                         # Return to SSH menu
        *) print_colored "$ERROR_COLOR" "❌ Invalid option!"; sleep 1 ;;  # Handle invalid input
    esac

done 