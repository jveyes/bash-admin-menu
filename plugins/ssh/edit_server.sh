# Edit SSH Server Script
# This script allows the user to update an existing SSH server's configuration interactively.

#!/bin/bash
clear
# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared SSH utility functions and variables
source "$SCRIPT_DIR/ssh_utils.sh"

print_colored "$TITLE_COLOR" "✏️  === Update SSH Server ==="
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

# Prompt user to select a server to edit
while true; do
    read -p "Select server number (or 0 to go back): " selection
    if [[ "$selection" == "0" ]]; then
        exit 0
    fi
    if [[ $selection =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#servers[@]} )); then
        server_name="${servers[$((selection-1))]}"
        break
    fi
    print_colored "$ERROR_COLOR" "❌ Invalid selection!"
done

# Extract current server fields
in_section=0
current_host=""; current_port=""; current_user=""; current_key=""; current_status=""
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    if [[ "$line" =~ ^\[$server_name\]$ ]]; then
        in_section=1
        continue
    elif [[ "$line" =~ ^\[.*\]$ ]] && [[ $in_section -eq 1 ]]; then
        break
    fi
    if [[ $in_section -eq 1 ]]; then
        [[ "$line" =~ ^host= ]] && current_host="${line#host=}"
        [[ "$line" =~ ^port= ]] && current_port="${line#port=}"
        [[ "$line" =~ ^user= ]] && current_user="${line#user=}"
        [[ "$line" =~ ^key_path= ]] && current_key="${line#key_path=}"
        [[ "$line" =~ ^status= ]] && current_status="${line#status=}"
    fi
done < "$SERVERS_CONFIG"

# Prompt for new values, default to current
read -p "🌐 Host/IP [$current_host]: " new_host
new_host=${new_host:-$current_host}
read -p "🔢 Port [$current_port]: " new_port
new_port=${new_port:-$current_port}
read -p "👤 Username [$current_user]: " new_user
new_user=${new_user:-$current_user}
read -p "🔑 SSH key path [$current_key]: " new_key
new_key=${new_key:-$current_key}

# Update the server block in the config file
# Use a temp file to safely update only the selected server
# Copy all lines, replacing only the selected server's fields

temp_file=$(mktemp)
in_section=0
while IFS= read -r line; do
    if [[ "$line" =~ ^\[$server_name\]$ ]]; then
        in_section=1
        echo "$line" >> "$temp_file"
        continue
    elif [[ "$line" =~ ^\[.*\]$ ]] && [[ $in_section -eq 1 ]]; then
        in_section=0
    fi
    if [[ $in_section -eq 1 ]]; then
        [[ "$line" =~ ^host= ]] && echo "host=$new_host" >> "$temp_file" && continue
        [[ "$line" =~ ^port= ]] && echo "port=$new_port" >> "$temp_file" && continue
        [[ "$line" =~ ^user= ]] && echo "user=$new_user" >> "$temp_file" && continue
        [[ "$line" =~ ^key_path= ]] && echo "key_path=$new_key" >> "$temp_file" && continue
        [[ "$line" =~ ^status= ]] && echo "status=$current_status" >> "$temp_file" && continue
        echo "$line" >> "$temp_file"
    else
        echo "$line" >> "$temp_file"
    fi
done < "$SERVERS_CONFIG"
mv "$temp_file" "$SERVERS_CONFIG"

# Notify user of success
print_colored "$SUCCESS_COLOR" "✅ Server '$server_name' updated!"
read -p "Press Enter to return to menu..." 