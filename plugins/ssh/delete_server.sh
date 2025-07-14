# Delete SSH Server Script
# This script allows the user to delete an SSH server from the configuration interactively.

#!/bin/bash
clear
# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared SSH utility functions and variables
source "$SCRIPT_DIR/ssh_utils.sh"

print_colored "$TITLE_COLOR" "🗑️  === Delete SSH Server ==="
echo

# Gather all server names from the config
servers=()
while IFS= read -r line; do
    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        servers+=("${BASH_REMATCH[1]}")
    fi
done < "$SERVERS_CONFIG"

# If no servers, notify and exit
if [[ ${#servers[@]} -eq 0 ]]; then
    print_colored "$WARNING_COLOR" "⚠️  No servers found!"
    read -p "Press Enter to return to menu..."
    exit 0
fi

echo "🖥️  Available servers:"
for i in "${!servers[@]}"; do
    echo "  $((i+1)). 🏷️  ${servers[i]}"
done
echo "  0. 🔙 Back"
echo

# Prompt user to select a server to delete
while true; do
    read -p "Select server number to delete (or 0 to go back): " selection
    if [[ "$selection" == "0" ]]; then
        exit 0
    fi
    if [[ $selection =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#servers[@]} )); then
        server_name="${servers[$((selection-1))]}"
        break
    fi
    print_colored "$ERROR_COLOR" "❌ Invalid selection!"
done

# Extract current server fields for confirmation
in_section=0
host=""; port=""; user=""; status=""
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    if [[ "$line" =~ ^\[$server_name\]$ ]]; then
        in_section=1
        continue
    elif [[ "$line" =~ ^\[.*\]$ ]] && [[ $in_section -eq 1 ]]; then
        break
    fi
    if [[ $in_section -eq 1 ]]; then
        [[ "$line" =~ ^host= ]] && host="${line#host=}"
        [[ "$line" =~ ^port= ]] && port="${line#port=}"
        [[ "$line" =~ ^user= ]] && user="${line#user=}"
        [[ "$line" =~ ^status= ]] && status="${line#status=}"
    fi
done < "$SERVERS_CONFIG"

echo "Server details:"
echo "  🏷️  Name: $server_name"
echo "  🌐 Host: $host:$port"
echo "  👤 User: $user"
echo "  🟢 Status: $status"
echo
# Confirm deletion
print_colored "$WARNING_COLOR" "⚠️  Are you sure you want to delete server '$server_name'?"
read -p "Type 'DELETE' to confirm: " confirmation
if [[ "$confirmation" != "DELETE" ]]; then
    print_colored "$INFO_COLOR" "❌ Deletion cancelled."
    read -p "Press Enter to return to menu..."
    exit 0
fi

# Remove the server block from the config file
# Use a temp file to safely remove only the selected server

temp_file=$(mktemp)
in_section=0
while IFS= read -r line; do
    if [[ "$line" =~ ^\[$server_name\]$ ]]; then
        in_section=1
        continue
    elif [[ "$line" =~ ^\[.*\]$ ]] && [[ $in_section -eq 1 ]]; then
        in_section=0
    fi
    if [[ $in_section -eq 0 ]]; then
        echo "$line" >> "$temp_file"
    fi
done < "$SERVERS_CONFIG"
mv "$temp_file" "$SERVERS_CONFIG"

# Notify user of success
print_colored "$SUCCESS_COLOR" "✅ Server '$server_name' deleted!"
read -p "Press Enter to return to menu..." 