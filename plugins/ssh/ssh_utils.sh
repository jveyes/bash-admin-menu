# SSH Utilities Script
# Shared configuration variables and utility functions for SSH Manager plugins.

#!/bin/bash

# Path to the SSH servers configuration file
SERVERS_CONFIG="config/ssh/servers.conf"
# Log file for SSH Manager actions
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/admin_menu.log"
# Color variables for output
TITLE_COLOR="green"
MENU_COLOR="white"
ERROR_COLOR="red"
SUCCESS_COLOR="green"
WARNING_COLOR="yellow"
INFO_COLOR="cyan"

# Function to get ANSI color code from color name
get_color_code() {
    local color_name="$1"
    case "$color_name" in
        "red") echo "31" ;;
        "green") echo "32" ;;
        "yellow") echo "33" ;;
        "blue") echo "34" ;;
        "magenta") echo "35" ;;
        "cyan") echo "36" ;;
        "white") echo "37" ;;
        *) echo "37" ;;
    esac
}

# Function to print colored text to the terminal
print_colored() {
    local color="$1"
    local text="$2"
    local color_code=$(get_color_code "$color")
    echo -e "\e[${color_code}m${text}\e[0m"
}

# Function to print a styled box around given lines
print_box() {
    local lines=("$@")
    local maxlen=0
    local line visible_line len
    for line in "${lines[@]}"; do
        visible_line=$(echo -e "$line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        len=${#visible_line}
        (( len > maxlen )) && maxlen=$len
    done
    local border_top="╭$(printf '─%.0s' $(seq 1 $((maxlen+2))))╮"
    local border_bot="╰$(printf '─%.0s' $(seq 1 $((maxlen+2))))╯"
    echo -e "$border_top"
    for line in "${lines[@]}"; do
        visible_line=$(echo -e "$line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        len=${#visible_line}
        printf "│ %b%*s │\n" "$line" $((maxlen-len)) ""
    done
    echo -e "$border_bot"
}

# Function to log an event to the log file
log_event() {
    local level="$1"
    local action="$2"
    local details="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Debug: print log file path
    echo "[DEBUG] Logging to: $LOG_FILE" >&2
    # Structure: [YYYY-MM-DD HH:MM:SS] [LEVEL] ACTION: DETAILS
    while IFS= read -r line; do
        echo "[$timestamp] [$level] $action: $line" >> "$LOG_FILE"
    done <<< "$details"
}
# Convenience wrapper for one-line logs
log_info() { log_event "INFO" "$1" "$2"; }
log_command() { log_event "COMMAND" "$1" "$2"; }
log_error() { log_event "ERROR" "$1" "$2"; }

# Function to show a loading spinner while a process runs
loading_spinner() {
    local pid=$1
    local spin='|/-\\'
    local i=0
    tput civis  # Hide cursor
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\rConnecting... ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r"  # Clear the line
    tput cnorm  # Show cursor
}

# Function to let the user select a server from servers.conf and output its fields
select_server() {
    local servers=()
    local server_name host user port key_path
    # Gather all server names
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[(.*)\]$ ]]; then
            servers+=("${BASH_REMATCH[1]}")
        fi
    done < "$SERVERS_CONFIG"
    if [[ ${#servers[@]} -eq 0 ]]; then
        print_colored "$ERROR_COLOR" "No servers found in config!"
        return 1
    fi
    echo "Available servers:"
    for i in "${!servers[@]}"; do
        echo "  $((i+1)). ${servers[i]}"
    done
    echo
    while true; do
        read -p "Select server number: " selection
        if [[ $selection =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#servers[@]} )); then
            server_name="${servers[$((selection-1))]}"
            break
        fi
        print_colored "$ERROR_COLOR" "Invalid selection!"
    done
    # Extract fields for the selected server
    in_section=0
    host=""; user=""; port=""; key_path=""
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
            [[ "$line" =~ ^user= ]] && user="${line#user=}"
            [[ "$line" =~ ^port= ]] && port="${line#port=}"
            [[ "$line" =~ ^key_path= ]] && key_path="${line#key_path=}"
        fi
    done < "$SERVERS_CONFIG"
    # Output as variables (for sourcing)
    SELECTED_SERVER_NAME="$server_name"
    SELECTED_SERVER_HOST="$host"
    SELECTED_SERVER_USER="$user"
    SELECTED_SERVER_PORT="$port"
    SELECTED_SERVER_KEY_PATH="$key_path"
    export SELECTED_SERVER_NAME SELECTED_SERVER_HOST SELECTED_SERVER_USER SELECTED_SERVER_PORT SELECTED_SERVER_KEY_PATH
} 