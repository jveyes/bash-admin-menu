#!/bin/bash
# Minimal, robust remote system info script
clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ssh_utils.sh"

print_colored "$TITLE_COLOR" "🖥️  System Version Info"
echo
select_server || { read -p "Press Enter to return..."; exit 1; }
host="$SELECTED_SERVER_HOST"
user="$SELECTED_SERVER_USER"
port="$SELECTED_SERVER_PORT"
key_path="$SELECTED_SERVER_KEY_PATH"

# Expand ~ in key_path if present
key_path="${key_path/#\~/$HOME}"

print_colored "$INFO_COLOR" "Connecting to $user@$host..."
log_command "System Info" "ssh -i $key_path -p $port $user@$host ... (system info commands)"
echo
print_colored "$INFO_COLOR" "================ SSH OUTPUT ================"
ssh -i "$key_path" -p "$port" -o ConnectTimeout=5 "$user@$host" bash <<'EOF'
echo -e "🖥️  Hostname: $(hostname 2>/dev/null || echo N/A)"
echo -e "🌐 Main IP: $(hostname -I 2>/dev/null | awk '{print $1}' || echo N/A)"
echo -e "⏳ Uptime: $(uptime -p 2>/dev/null || echo N/A)"
echo -e "🖥️  Kernel: $(uname -r 2>/dev/null || echo N/A)"
echo -e "📦 OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo N/A)"
echo -e "🔢 Arch: $(uname -m 2>/dev/null || echo N/A)"
echo -e "🧩 Distro: $(lsb_release -d 2>/dev/null | cut -f2- || grep ^NAME= /etc/os-release | head -1 | cut -d= -f2 | tr -d '"' || echo N/A)"
EOF
status=$?
print_colored "$INFO_COLOR" "================ END OF OUTPUT ================"
if [ $status -ne 0 ]; then
    print_colored "$ERROR_COLOR" "❌ SSH error occurred (see above)."
    log_error "System Info" "SSH error occurred for $user@$host"
fi
read -p "Press Enter to return..." 