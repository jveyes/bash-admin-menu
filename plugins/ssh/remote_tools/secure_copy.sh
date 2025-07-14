#!/bin/bash
# Secure file copy (scp/rsync) to/from a remote server
clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ssh_utils.sh"

print_colored "$TITLE_COLOR" "📤 Secure File Copy (scp/rsync)"
echo
# Let user select a server from config
select_server || { read -p "Press Enter to return..."; exit 1; }
host="$SELECTED_SERVER_HOST"
user="$SELECTED_SERVER_USER"
port="$SELECTED_SERVER_PORT"
key_path="$SELECTED_SERVER_KEY_PATH"
# Prompt for copy direction
echo "1. Upload local file to remote (scp)"
echo "2. Download remote file to local (scp)"
echo "3. Use rsync (advanced)"
read -p "Select an option: " direction
log_info "Secure Copy" "User selected direction: $direction"
case $direction in
    1)
        read -p "Local file path: " local
        read -p "Remote path: " remote
        log_command "SCP Upload" "scp -i $key_path -P $port $local $user@$host:$remote"
        if scp -i "$key_path" -P "$port" "$local" "$user@$host:$remote"; then
            print_colored "$SUCCESS_COLOR" "✅ File uploaded successfully."
            log_info "SCP Upload" "File uploaded: $local to $user@$host:$remote"
        else
            print_colored "$ERROR_COLOR" "❌ Upload failed."
            log_error "SCP Upload" "Upload failed: $local to $user@$host:$remote"
        fi
        ;;
    2)
        read -p "Remote file path: " remote
        read -p "Local destination path: " local
        log_command "SCP Download" "scp -i $key_path -P $port $user@$host:$remote $local"
        if scp -i "$key_path" -P "$port" "$user@$host:$remote" "$local"; then
            print_colored "$SUCCESS_COLOR" "✅ File downloaded successfully."
            log_info "SCP Download" "File downloaded: $user@$host:$remote to $local"
        else
            print_colored "$ERROR_COLOR" "❌ Download failed."
            log_error "SCP Download" "Download failed: $user@$host:$remote to $local"
        fi
        ;;
    3)
        read -p "Enter full rsync command (e.g. rsync -avz -e 'ssh -i $key_path -p $port' file user@host:/path): " cmd
        log_command "RSYNC" "$cmd"
        eval "$cmd"
        ;;
    *)
        print_colored "$ERROR_COLOR" "❌ Invalid option."
        log_error "Secure Copy" "Invalid direction: $direction"
        ;;
esac
read -p "Press Enter to return..." 