# Connect to SSH Server Script
# This script allows the user to select a server and connect to it via SSH.

#!/bin/bash
# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source shared SSH utility functions and variables
source "$SCRIPT_DIR/ssh_utils.sh"

print_colored "$TITLE_COLOR" "🔗 === Connect to SSH Server ==="
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
    print_colored "$WARNING_COLOR" "No servers found!"
    read -p "Press Enter to return to menu..."
    exit 0
fi

echo "🖥️  Available servers:"
# Print all available servers
for i in "${!servers[@]}"; do
    echo "  $((i+1)). 🏷️  ${servers[i]}"
done
echo "  0. 🔙 Back"
echo

# Prompt user to select a server to connect
while true; do
    read -p "Select server number (or 0 to go back): " selection
    log_info "Connect Server" "User selected: $selection"
    if [[ "$selection" == "0" ]]; then
        exit 0
    fi
    if [[ $selection =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#servers[@]} )); then
        server_name="${servers[$((selection-1))]}"
        break
    fi
    print_colored "$ERROR_COLOR" "Invalid selection!"
done

# Extract server fields for connection
in_section=0
host=""; port=""; user=""; key_path=""; status=""; last_used=""
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
        [[ "$line" =~ ^key_path= ]] && key_path="${line#key_path=}"
        [[ "$line" =~ ^status= ]] && status="${line#status=}"
        [[ "$line" =~ ^last_used= ]] && last_used="${line#last_used=}"
    fi
done < "$SERVERS_CONFIG"

# Expand ~ to home directory for key path
key_path="${key_path/#\~/$HOME}"

# Show connection details
print_colored "$INFO_COLOR" "Connecting to: 🏷️  $server_name"
print_colored "$INFO_COLOR" "🌐 Host: $host:$port"
print_colored "$INFO_COLOR" "👤 User: $user"
print_colored "$INFO_COLOR" "🔑 Key path: $key_path"
print_colored "$INFO_COLOR" "🟢 Status: $status"
print_colored "$INFO_COLOR" "🕒 Last used: $last_used"
log_command "SSH" "ssh -i $key_path -p $port $user@$host"
echo

# Test connection with spinner
(ssh -i "$key_path" -p "$port" -o BatchMode=yes -o ConnectTimeout=5 "$user@$host" true) &
test_pid=$!
loading_spinner $test_pid
wait $test_pid
status=$?
if [ $status -eq 0 ]; then
    printf "\r✅ Connection established!           \n"
    log_info "Connect Server" "Connection established to $server_name ($host) as $user"
    ssh -i "$key_path" -p "$port" "$user@$host"
    print_colored "$SUCCESS_COLOR" "✅ Disconnected from $server_name"
    log_info "Connect Server" "Disconnected from $server_name ($host) as $user"
else
    printf "\r❌ Connection failed!                \n"
    print_colored "$ERROR_COLOR" "❌ Could not connect to $server_name"
    log_error "Connect Server" "Connection failed to $server_name ($host) as $user"
fi
read -p "Press Enter to return to menu..." 