# Add New SSH Server Script
# This script allows the user to add a new SSH server to the configuration interactively.

#!/bin/bash
clear
# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared SSH utility functions and variables
source "$SCRIPT_DIR/ssh_utils.sh"

print_colored "$TITLE_COLOR" "=== Add New SSH Server ==="
echo

# Prompt for server name, allow cancel with 'q'
while true; do
    read -p "Server name (or q to cancel): " server_name
    if [[ "$server_name" =~ ^[qQ]$ ]]; then
        print_colored "$INFO_COLOR" "Server addition cancelled."
        read -p "Press Enter to return to menu..."
        exit 0
    fi
    if [[ -z "$server_name" ]]; then
        print_colored "$ERROR_COLOR" "Server name cannot be empty!"
        continue
    fi
    # Check if server already exists
    if grep -q "^\[$server_name\]" "$SERVERS_CONFIG" 2>/dev/null; then
        print_colored "$ERROR_COLOR" "Server '$server_name' already exists!"
        continue
    fi
    break
done

# Prompt for host/IP, allow cancel with 'q'
while true; do
    read -p "Host/IP address (or q to cancel): " host
    if [[ "$host" =~ ^[qQ]$ ]]; then
        print_colored "$INFO_COLOR" "Server addition cancelled."
        read -p "Press Enter to return to menu..."
        exit 0
    fi
    if [[ -z "$host" ]]; then
        print_colored "$ERROR_COLOR" "Host cannot be empty!"
        continue
    fi
    break
done

# Prompt for port, allow cancel with 'q', default to 22
while true; do
    read -p "Port (default: 22, or q to cancel): " port
    if [[ "$port" =~ ^[qQ]$ ]]; then
        print_colored "$INFO_COLOR" "Server addition cancelled."
        read -p "Press Enter to return to menu..."
        exit 0
    fi
    port=${port:-22}
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        print_colored "$ERROR_COLOR" "Invalid port number! Must be 1-65535."
        continue
    fi
    break
done

# Prompt for username, allow cancel with 'q', default to ubuntu
read -p "Username (default: ubuntu, or q to cancel): " user
if [[ "$user" =~ ^[qQ]$ ]]; then
    print_colored "$INFO_COLOR" "Server addition cancelled."
    read -p "Press Enter to return to menu..."
    exit 0
fi
user=${user:-ubuntu}

# Prompt for SSH key path, allow cancel with 'q', default to ~/.ssh/id_rsa
read -p "SSH key path (default: ~/.ssh/id_rsa, or q to cancel): " key_path
if [[ "$key_path" =~ ^[qQ]$ ]]; then
    print_colored "$INFO_COLOR" "Server addition cancelled."
    read -p "Press Enter to return to menu..."
    exit 0
fi
key_path=${key_path:-~/.ssh/id_rsa}

echo
# Show summary of server details to add
print_colored "$INFO_COLOR" "Server details to add:"
echo "   🏷️  Name: $server_name"
echo "   🌐 Host: $host:$port"
echo "   👤 User: $user"
echo "   🔑 Key: $key_path"
echo
# Confirm addition
read -p "➕ Add this server? (y/N): " -n 1 -r
REPLY=${REPLY,,}
echo
if [[ "$REPLY" != "y" ]]; then
    print_colored "$INFO_COLOR" "❌ Server addition cancelled."
    read -p "Press Enter to return to menu..."
    exit 0
fi

# Append new server block to config file
{
    echo ""
    echo "[$server_name]"
    echo "host=$host"
    echo "port=$port"
    echo "user=$user"
    echo "key_path=$key_path"
    echo "last_used=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "status=active"
} >> "$SERVERS_CONFIG"

# Notify user of success
print_colored "$SUCCESS_COLOR" "✅ Server '$server_name' added!"
read -p "Press Enter to return to menu..." 