# List SSH Servers Script
# This script lists all SSH servers in a compact, single-line format.

#!/bin/bash
clear
# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared SSH utility functions and variables
source "$SCRIPT_DIR/ssh_utils.sh"

print_colored "$TITLE_COLOR" "📋 === SSH Servers List ==="
echo
servers=()
current_server=""

# Gather all server names from the config
while IFS= read -r line; do
    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        current_server="${BASH_REMATCH[1]}"
        servers+=("$current_server")
    fi
done < "$SERVERS_CONFIG"

# If no servers, notify and exit
if [[ ${#servers[@]} -eq 0 ]]; then
    print_colored "$WARNING_COLOR" "⚠️  No servers found!"
    echo
    read -p "Press Enter to return to menu..."
    exit 0
fi

echo "🖥️  Available servers:"
# For each server, extract and print its details in a single line
for i in "${!servers[@]}"; do
    server_name="${servers[i]}"
    in_section=0
    host=""; port=""; user=""; status=""; last_used=""
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
            [[ "$line" =~ ^last_used= ]] && last_used="${line#last_used=}"
        fi
    done < "$SERVERS_CONFIG"
    # Print server info in a compact, single line
    print_colored "$MENU_COLOR" "$((i+1)). 🔐 $server_name"
    line="    🌐 $host:$port | 👤 $user | "
    if [[ "$status" == "active" ]]; then
        line+="✅ Status: $status"
    else
        line+="❌ Status: $status"
    fi
    line+=" | 🕒 Last used: $last_used"
    print_colored "$MENU_COLOR" "$line"
    echo
    done
# Print total number of servers
print_colored "$SUCCESS_COLOR" "📊 Total servers: ${#servers[@]}"
echo
read -p "Press Enter to return to menu..." 