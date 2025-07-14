#!/bin/bash
# Minimal, robust remote usage info script (fixed quoting)
clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ssh_utils.sh"

print_colored "$TITLE_COLOR" "💾 Disk, RAM, and CPU Usage"
echo
select_server || { read -p "Press Enter to return..."; exit 1; }
host="$SELECTED_SERVER_HOST"
user="$SELECTED_SERVER_USER"
port="$SELECTED_SERVER_PORT"
key_path="$SELECTED_SERVER_KEY_PATH"

print_colored "$INFO_COLOR" "Connecting to $user@$host..."
log_command "Check Usage" "ssh -i $key_path -p $port $user@$host ... (check usage commands)"
echo
print_colored "$INFO_COLOR" "================ SSH OUTPUT ================"
ssh -i "$key_path" -p "$port" -o ConnectTimeout=5 "$user@$host" bash <<'EOF'
echo -e "💽 Disk: $(df -h / 2>/dev/null | awk 'NR==2{print $3 " used of " $2 " (" $5 ")"}' || echo N/A)"
echo -e "🧠 RAM: $(free -m 2>/dev/null | awk '/Mem:/ {printf "%dMB used of %dMB (%.1f%%)", $3, $2, $3/$2*100}' || echo N/A)"
echo -e "🖥️  CPU: $(top -b -n1 2>/dev/null | grep 'Cpu(s)' | awk '{print "user: " $2 "% sys: " $4 "% idle: " $8 "%"}' || echo N/A)"
EOF
status=$?
print_colored "$INFO_COLOR" "================ END OF OUTPUT ================"
if [ $status -ne 0 ]; then
    print_colored "$ERROR_COLOR" "❌ SSH error occurred (see above)."
    log_error "Check Usage" "SSH error occurred for $user@$host"
fi
read -p "Press Enter to return..." 