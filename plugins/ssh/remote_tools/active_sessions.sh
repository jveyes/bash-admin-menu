#!/bin/bash
# Minimal, robust remote active sessions info script (fixed quoting)
clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ssh_utils.sh"

print_colored "$TITLE_COLOR" "👥 Active Sessions and Connections"
echo
select_server || { read -p "Press Enter to return..."; exit 1; }
host="$SELECTED_SERVER_HOST"
user="$SELECTED_SERVER_USER"
port="$SELECTED_SERVER_PORT"
key_path="$SELECTED_SERVER_KEY_PATH"

print_colored "$INFO_COLOR" "Connecting to $user@$host..."
log_command "Active Sessions" "ssh -i $key_path -p $port $user@$host ... (active sessions commands)"
echo
print_colored "$INFO_COLOR" "================ SSH OUTPUT ================"
ssh -i "$key_path" -p "$port" -o ConnectTimeout=5 "$user@$host" bash <<'EOF'
echo -e "👤 Users: $(w -h 2>/dev/null | awk '{print $1}' | sort | uniq -c | awk '{print $2 "(" $1 " session(s))"}' | paste -sd ', ' - || echo N/A)"
echo -e "🔗 Top Connections:"
ss -tunap 2>/dev/null | head -6 | tail -5 || echo N/A
EOF
status=$?
print_colored "$INFO_COLOR" "================ END OF OUTPUT ================"
if [ $status -ne 0 ]; then
    print_colored "$ERROR_COLOR" "❌ SSH error occurred (see above)."
    log_error "Active Sessions" "SSH error occurred for $user@$host"
fi
read -p "Press Enter to return..." 