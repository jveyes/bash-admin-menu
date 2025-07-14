#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared SSH utility functions and variables
source "$SCRIPT_DIR/ssh_utils.sh"

# Function to display the SSH menu
show_ssh_menu() {
    clear  # Clear the terminal screen
    # Print a styled box with the menu title and subtitle
    print_box \
        "$(print_colored "$TITLE_COLOR" "SSH Server Manager")" \
        "$(print_colored "$INFO_COLOR" "Manage your SSH servers and connections")"
    echo
    # Print menu options with emojis
    echo "1. 📋 List Servers"
    echo "2. ➕ Add Server"
    echo "3. ✏️  Edit Server"
    echo "4. 🗑️  Delete Server"
    echo "5. 🔗 Connect to Server"
    echo "6. 🛠️  Remote Tools"
    echo
    echo "q. ❌ Quit"
    echo
}

# Main loop: show the menu and handle user input
while true; do
    show_ssh_menu  # Display the menu
    read -p "Select an option: " choice  # Prompt user for input
    log_info "SSH Menu" "User selected option: $choice"
    case $choice in
        1) "$SCRIPT_DIR/list_servers.sh" ;;      # List servers
        2) "$SCRIPT_DIR/add_server.sh" ;;        # Add a new server
        3) "$SCRIPT_DIR/edit_server.sh" ;;       # Edit an existing server
        4) "$SCRIPT_DIR/delete_server.sh" ;;     # Delete a server
        5) "$SCRIPT_DIR/connect_server.sh" ;;    # Connect to a server
        6) "$SCRIPT_DIR/remote_tools_menu.sh" ;;    # Remote tools submenu
        q|Q) break ;;                            # Quit the menu
        *) print_colored "$ERROR_COLOR" "❌ Invalid option!"; sleep 1 ;;  # Handle invalid input
    esac

done 