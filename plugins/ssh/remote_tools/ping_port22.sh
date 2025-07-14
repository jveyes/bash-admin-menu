#!/bin/bash
# Minimal, robust remote ping port 22 script (fixed quoting)
clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ssh_utils.sh"

print_colored "$TITLE_COLOR" "📡 Ping port 22 (SSH)"
echo
select_server || { read -p "Press Enter to return..."; exit 1; }
host="$SELECTED_SERVER_HOST"
user="$SELECTED_SERVER_USER"
port="$SELECTED_SERVER_PORT"
key_path="$SELECTED_SERVER_KEY_PATH"

print_colored "$INFO_COLOR" "Pinging port 22 on $host..."
log_command "Ping Port 22" "ssh -i $key_path -p $port $user@$host ... (ping port 22 commands)"
echo
print_colored "$INFO_COLOR" "================ SSH OUTPUT ================"
# Use nc (netcat) to check port 22 remotely
ssh -i "$key_path" -p "$port" -o ConnectTimeout=5 "$user@$host" bash <<'EOF'
if nc -z -w3 localhost 22 2>/dev/null; then
    echo -e "✅ Port 22 is open on remote host (localhost)"
else
    echo -e "❌ Port 22 is closed or unreachable on remote host (localhost)"
fi
EOF
status=$?
print_colored "$INFO_COLOR" "================ END OF OUTPUT ================"
if [ $status -ne 0 ]; then
    print_colored "$ERROR_COLOR" "❌ SSH error occurred (see above)."
    log_error "Ping Port 22" "SSH error occurred for $user@$host"
fi
read -p "Press Enter to return..." 