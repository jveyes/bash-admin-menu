#!/bin/bash

################################################################################
# Bash Script Information
# -----------------------
# Description: This Bash script provides an interactive menu with three
#              commands and an option to exit. The commands demonstrate
#              different functionalities, such as displaying local user
#              information, reading a name, and showing disk information.
# Date:        January 15, 2024
# Creator:     JESUS VILLALOBOS (inspired by assistance from OpenAI's GPT-3)
# Version:     1.2
# License:     MIT License
# Updates:     Added input validation (v1.1), Added interrupt handling (v1.2)
################################################################################

# Global variables for interrupt handling
interrupt_count=0
max_interrupts=3

# Page size for pagination
PAGE_SIZE=7
current_page=1

# Language/config selection logic
CONFIG_FILE=""

# Parse -l <configfile> argument (for language)
while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--language)
      CONFIG_FILE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Default to English config if not set
if [[ -z "$CONFIG_FILE" ]]; then
  CONFIG_FILE="config/menu.en.conf"
fi

# 1. Warning for language fallback
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "\e[33m$(msgf LANG_FALLBACK_WARNING "$CONFIG_FILE")\e[0m"
  CONFIG_FILE="config/menu.en.conf"
fi

# 2. In log view: replace '--- Log File ---' and 'Log file is empty.'
if [[ "$plugin_script" == "__view_log__" ]]; then
  log_event "INFO" "view_log" "" "success" "$(msgf LOG_EVENT_VIEWED)"
  echo -e "\n$(msgf LOG_VIEW_TITLE)\n"
  if [[ -s "$LOG_FILE" ]]; then
    less "$LOG_FILE"
  else
    echo "$(msgf LOG_FILE_EMPTY)"
    sleep 2
  fi
  task_ended "${menu_options[$idx]}"
  continue
elif [[ "$plugin_script" == "__clear_log__" ]]; then
  log_event "WARNING" "clear_log" "" "success" "$(msgf LOG_EVENT_CLEARED)"
  > "$LOG_FILE"
  echo "$(msgf LOG_FILE_CLEARED)"
  sleep 1
  task_ended "${menu_options[$idx]}"
  continue
fi

# 3. Unsupported OS error
if [[ "$OS" == "Unknown" ]]; then
  echo -e "\e[31m$(msgf UNSUPPORTED_OS "$OS_TYPE")\e[0m"
  exit 1
fi

# Read configuration from selected file

# Function to print a simple box in pure Bash (no Python, no wcwidth)
print_box_bash() {
    local lines=("$@")
    local maxlen=0
    local line visible_line len
    # Calculate the maximum width (not considering emoji visual width)
    for line in "${lines[@]}"; do
        # Remove ANSI color codes
        visible_line=$(echo -e "$line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        len=$(display_width "$visible_line")
        (( len > maxlen )) && maxlen=$len
    done
    local border_top="╭$(printf '─%.0s' $(seq 1 $((maxlen+2))))╮"
    local border_bot="╰$(printf '─%.0s' $(seq 1 $((maxlen+2))))╯"
    echo -e "$border_top"
    for line in "${lines[@]}"; do
        visible_line=$(echo -e "$line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        len=$(display_width "$visible_line")
        printf "│ %b%*s │\n" "$line" $((maxlen-len)) ""
    done
    echo -e "$border_bot"
}

# Function to get color code
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
        *) echo "37" ;; # default to white
    esac
}

# Function to handle script interruption (Ctrl+C)
handle_interrupt() {
    interrupt_count=$((interrupt_count + 1))
    echo ""
    if [[ $interrupt_count -eq 1 ]]; then
        local warning_color="\e[$(get_color_code "$WARNING_COLOR")m"
        print_box_bash \
            "${warning_color}$(msgf WARNING_INTERRUPT)\e[0m" \
            "${warning_color}$(msgf WARNING_INTERRUPT2)\e[0m" \
            "${warning_color}$(msgf WARNING_INTERRUPT3)\e[0m"
        sleep 3 &
        sleep_pid=$!
        wait $sleep_pid 2>/dev/null
        if [[ $interrupt_count -eq 1 ]]; then
            interrupt_count=0
            return
        fi
    fi
    if [[ $interrupt_count -ge 2 ]]; then
        local error_color="\e[$(get_color_code "$ERROR_COLOR")m"
        print_box_bash \
            "${error_color}$(msgf FORCE_EXIT)\e[0m" \
            "${error_color}$(msgf FORCE_EXIT_CLEAN)\e[0m"
        cleanup_and_exit
    fi
}

# Function to cleanup and exit gracefully
cleanup_and_exit() {
    echo ""
    local success_color="\e[$(get_color_code "$SUCCESS_COLOR")m"
    if [[ ${#EXIT_BOX_LINES[@]} -gt 0 ]]; then
        print_box_bash "${EXIT_BOX_LINES[@]}"
    else
        print_box_bash \
            "${success_color}$(msgf EXIT_THANKS "$(msgf APP_NAME)")\e[0m" \
            "${success_color}$(msgf EXIT_GOODBYE)\e[0m"
    fi
    echo ""
    echo -e "\e[0m"
    log_event "INFO" "session_end" "" "success" "$(msgf LOG_EVENT_SESSION_ENDED)"
    exit 0
}

# Set up signal handlers
trap handle_interrupt SIGINT SIGTERM

# Variables por defecto
PAGE_SIZE=7
BORDER_CHAR="#"
TITLE_COLOR="green"
MENU_COLOR="white"
ERROR_COLOR="red"
SUCCESS_COLOR="green"
WARNING_COLOR="yellow"
LOGGING_ENABLED=true
LOG_FILE="admin_menu.log"
LOG_LEVEL="INFO"
PLUGIN_DIR="plugins"
AUTO_DISCOVER=true
DEFAULT_SECTION="MENU"
BACK_COMMAND="BACK"
EXIT_COMMAND="exit.sh"
EXIT_BOX_LINES=()

menu_options=()
menu_plugins=()

# --- Submenú: pila de menús ---
menu_stack=()
page_stack=()
current_menu_section="$DEFAULT_SECTION"

# Función para cargar opciones de un menú dado
load_menu_section() {
    local section="$1"
    menu_options=()
    menu_plugins=()
    local in_section=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%\r}"
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^\[([A-Z_]+(:[A-Za-z0-9_]+)?)\] ]]; then
            [[ "${BASH_REMATCH[1]}" == "$section" ]] && in_section=1 || in_section=0
            continue
        fi
        if (( in_section )); then
            IFS='|' read -r menu_text plugin_name <<< "$line"
            menu_options+=("$menu_text")
            menu_plugins+=("$plugin_name")
        fi
    done < "$CONFIG_FILE"
}

# Leer solo las líneas de [EXIT_BOX] correctamente
EXIT_BOX_LINES=()
declare -A MSG
current_section=""
inside_exit_box=0
while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%\r}"
    if [[ "$line" =~ ^\[EXIT_BOX\] ]]; then
        inside_exit_box=1
        continue
    fi
    if [[ "$line" =~ ^\[.*\] ]]; then
        inside_exit_box=0
        # Detect and set current_section for other uses
        if [[ "$line" =~ ^\[([A-Z_]+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
        fi
        continue
    fi
    if (( inside_exit_box )); then
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        EXIT_BOX_LINES+=("$line")
        continue
    fi
    if [[ "$current_section" == "MESSAGES" ]]; then
        if [[ "$line" =~ ^([A-Z_]+)=(.*)$ ]]; then
            MSG[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
        fi
    fi

done < "$CONFIG_FILE"

# Función para formatear mensajes con variables
msgf() {
    local key="$1"; shift
    local message="${MSG[$key]}"
    if [[ $# -gt 0 ]]; then
        printf "$message" "$@"
    else
        printf "%b" "$message"
    fi
}

# Inicial: cargar menú principal
load_menu_section "$current_menu_section"

# Debug: print config file and INFO_PAGE_OPTIONS value
>&2 echo "[DEBUG] Using config file: $CONFIG_FILE"
>&2 echo "[DEBUG] INFO_PAGE_OPTIONS: '$(msgf INFO_PAGE_OPTIONS)'"

# Debug: print all MSG keys and values after loading config
>&2 echo "[DEBUG] MSG dictionary contents:"; for k in "${!MSG[@]}"; do >&2 echo "[DEBUG] $k = '${MSG[$k]}'"; done

PLUGINS_DIR="$(dirname "$0")/$PLUGIN_DIR"

# Function to validate user input
validate_input() {
    local input="$1"
    local min_option=$((start_idx+1))
    local max_option=$((end_idx+1))
    local error_color="\e[$(get_color_code "$ERROR_COLOR")m"
    local menu_color="\e[$(get_color_code "$MENU_COLOR")m"
    
    # Check if input is empty
    if [[ -z "$input" ]]; then
        echo ""
        echo -e "${error_color}$(msgf ERROR_NO_INPUT)\e[0m"
        echo -e "${menu_color}$(msgf HELP_RANGE $min_option $max_option)\e[0m"
        echo ""
        return 1
    fi
    
    # Check if input contains only digits
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        echo ""
        echo -e "${error_color}$(msgf ERROR_INVALID_INPUT "$input")\e[0m"
        echo -e "${menu_color}$(msgf HELP_DIGITS)\e[0m"
        echo ""
        return 1
    fi
    
    # Check if input is within valid range for the current page
    if (( input < min_option || input > max_option )); then
        echo ""
        echo -e "${error_color}$(msgf ERROR_OUT_OF_RANGE "$input")\e[0m"
        echo -e "${menu_color}$(msgf HELP_RANGE $min_option $max_option)\e[0m"
        echo ""
        return 1
    fi
    
    return 0
}

# Function to display the menu (mejorada)
display_menu() {
  clear
  local total_options=${#menu_options[@]}
  local total_pages=$(( (total_options + PAGE_SIZE - 1) / PAGE_SIZE ))
  local start_idx=$(( (current_page - 1) * PAGE_SIZE ))
  local end_idx=$(( start_idx + PAGE_SIZE - 1 ))
  (( end_idx >= total_options )) && end_idx=$((total_options - 1))
  
  # Determinar el nombre del menú actual para la cabecera
  local menu_title="$(msgf APP_NAME)"
  if [[ "$current_menu_section" =~ ^SUBMENU:(.+)$ ]]; then
    local submenu_key="SUBMENU:${BASH_REMATCH[1]}"
    local submenu_label=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%\r}"
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      # Remove spaces around pipe and compare
      local clean_line="$(echo "$line" | sed 's/ *| */|/g')"
      if [[ "$clean_line" =~ \|$submenu_key$ ]]; then
        IFS='|' read -r label _ <<< "$clean_line"
        submenu_label="${label//\"/}"
        submenu_label="$(echo -e "$submenu_label" | sed -e 's/^ *//' -e 's/ *$//')"
        break
      fi
    done < "$CONFIG_FILE"
    if [[ -n "$submenu_label" ]]; then
      menu_title="$(msgf APP_NAME)  -->  $submenu_label"
    else
      local fallback="${BASH_REMATCH[1]//_/ }"
      fallback="${fallback^^}"
      menu_title="$(msgf APP_NAME)  -->  $fallback"
    fi
  fi
  
  # Calcular el ancho máximo del menú
  max_length=0
  for ((i=start_idx; i<=end_idx; i++)); do
    option=" $((i+1)). ${menu_options[$i]}"
    visible_line=$(echo -e "$option" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    len=$(display_width "$visible_line")
    (( len > max_length )) && max_length=$len
  done

  # Calcular el ancho total considerando el nombre de la app (sin ANSI)
  local app_name_visible="$(echo -e "$menu_title" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')"
  local app_name_length=$(display_width "$app_name_visible")
  local content_width=$((app_name_length > max_length ? app_name_length : max_length))
  # Hacer el marco 20% más grande (redondeando hacia arriba)
  local padded_width=$(( (content_width * 12 + 9) / 10 ))

  local title_color="\e[1;$(get_color_code "$TITLE_COLOR")m"
  local menu_color="\e[$(get_color_code "$MENU_COLOR")m"

  # Mostrar la caja unificada
  local border_top="╭$(printf '─%.0s' $(seq 1 $padded_width))╮"
  local border_bot="╰$(printf '─%.0s' $(seq 1 $padded_width))╯"

  echo -e "${title_color}$border_top\e[0m"

  # Línea del nombre de la app (padding solo con longitud visible)
  local app_line=" ${menu_color}$menu_title\e[0m"
  local app_padding=$((padded_width - app_name_length - 1))
  printf "${title_color}│%b%*s${title_color}│\e[0m\n" "$app_line" "$app_padding" ""

  # Línea separadora (exactamente el ancho interior de la caja)
  local separator_width=$((padded_width))
  local separator="$(printf '─%.0s' $(seq 1 $separator_width))"
  echo -e "${title_color}│${separator}│\e[0m"

  # Opciones del menú
  for ((i=start_idx; i<=end_idx; i++)); do
    option=" $((i+1)). ${menu_options[$i]}"
    visible_line=$(echo -e "$option" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    len=$(display_width "$visible_line")
    padding=$((padded_width - len))
    printf "${title_color}│%s%*s│\e[0m\n" "$option" "$padding" ""
  done

  echo -e "${title_color}$border_bot\e[0m"
  
  # Prompt con paginación
  local range_text=""
  if (( start_idx+1 == end_idx+1 )); then
    range_text=""
  else
    range_text="(${start_idx+1}-${end_idx+1})"
  fi
  local total_options=${#menu_options[@]}
  local total_pages=$(( (total_options + PAGE_SIZE - 1) / PAGE_SIZE ))
  local info_line=""
  if (( total_pages > 1 )); then
    info_line=" $(msgf INFO_PAGE_OPTIONS "$(msgf APP_NAME)" "$current_page" "$total_pages" "$range_text") "
  else
    info_line=" $(msgf INFO_OPTIONS "$total_options" "$range_text") "
  fi
  echo -e "\e[42m$info_line\e[0m\n"
}

# Function to execute command 1
execute_command1() {
    # Displays a message indicating the execution of Command 1
    echo "$(msgf EXEC_COMMAND1)"
    echo -n "$(msgf USERNAME)" 
    whoami
    # Add your command(s) here
}

# Function to execute command 2
execute_command2() {
    # Prompts the user to enter a value for Command 2
    echo "$(msgf EXEC_COMMAND2)"
    read -p "$(msgf EXEC_COMMAND2_PROMPT)" name
    # Displays a message indicating the execution of Command 2 with the provided parameter
    echo -e "$(msgf EXEC_COMMAND2_RESULT "$name")"
    # Add your command(s) here using $param
}

# Barra de progreso simple para comandos largos
progress_bar() {
    local duration=${1:-3}
    echo -n "$(msgf PROGRESS_START)"
    for ((i=0; i<$duration; i++)); do
        echo -n "$(msgf PROGRESS_CHAR)"
        sleep 1
    done
    echo "$(msgf PROGRESS_DONE)"
}

# Function to execute command 3 (mejorada)
execute_command3() {
    echo "$(msgf EXEC_COMMAND3)"
    progress_bar 3
    df -h | column -t
}

# Function to start task
task_started() {
    local task_name="${1^^}"
    local prefix="$(msgf TASK_STARTED "")"
    local color_start="\e[1;33m"
    local color_name="\e[1;37m"
    local color_end="\e[0m"
    local box_width=45  # 47 total (bordes incluidos)
    # Construir la línea real con colores (usando escapes reales)
    local colored_line=" ${prefix}${color_name}${task_name}${color_start}"
    # Eliminar códigos ANSI para el cálculo de longitud visible
    local visible_line=$(echo -e "$colored_line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local visible_len=$(display_width "$visible_line")
    local padding=$((box_width - visible_len))
    echo ""
    echo -e "${color_start}╭─────────────────────────────────────────────╮${color_end}"
    printf "%b" "${color_start}│"
    printf "%b%*s%b" "$colored_line" "$padding" "" "│${color_end}\n"
    echo -e "${color_start}╰─────────────────────────────────────────────╯${color_end}"
}

# Function to end task
task_ended() {
    local task_name="${1^^}"
    local prefix="$(msgf TASK_FINISHED "")"
    local color_start="\e[1;32m"
    local color_name="\e[1;37m"
    local color_end="\e[0m"
    local box_width=45  # 47 total (bordes incluidos)
    # Construir la línea real con colores (usando escapes reales)
    local colored_line=" ${prefix}${color_name}${task_name}${color_start}"
    # Eliminar códigos ANSI para el cálculo de longitud visible
    local visible_line=$(echo -e "$colored_line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local visible_len=$(display_width "$visible_line")
    local padding=$((box_width - visible_len))
    echo ""
    echo -e "${color_start}╭─────────────────────────────────────────────╮${color_end}"
    printf "%b" "${color_start}│"
    printf "%b%*s%b" "$colored_line" "$padding" "" "│${color_end}\n"
    echo -e "${color_start}╰─────────────────────────────────────────────╯${color_end}"
}

# --- Log rotation and session ID setup ---
LOG_ROTATE_SIZE=$((1024*1024)) # 1MB
SESSION_ID="$(date +%Y%m%d_%H%M%S)_$$"

rotate_log_if_needed() {
  if [[ -f "$LOG_FILE" ]]; then
    local size=$(stat -c%s "$LOG_FILE")
    if (( size > LOG_ROTATE_SIZE )); then
      local ts=$(date +%Y%m%d_%H%M%S)
      mv "$LOG_FILE" "${LOG_FILE%.log}_$ts.log"
      touch "$LOG_FILE"
    fi
  fi
}

# --- Enhanced Logging Function with session ID and rotation ---
log_event() {
    local level="$1"
    local action="$2"
    local plugin="$3"
    local status="$4"
    local message="$5"
    local user
    user=$(whoami)
    local logfile="$(dirname "$0")/$LOG_FILE"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    rotate_log_if_needed
    echo "$timestamp | session: $SESSION_ID | user: $user | level: $level | action: $action | plugin: $plugin | status: $status | message: $message" >> "$logfile"
}

# Log session start
log_event "INFO" "session_start" "" "success" "$(msgf LOG_EVENT_SESSION_STARTED)"

# Function to show app info
show_app_info() {
    local title_color="\e[1;$(get_color_code "$TITLE_COLOR")m"
    local menu_color="\e[$(get_color_code "$MENU_COLOR")m"
    local app_name_length=$(display_width "$(echo -e "$APP_NAME" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')")
    local box_width=$((app_name_length + 8))
    local border_top="╭$(printf '─%.0s' $(seq 1 $box_width))╮"
    local border_bot="╰$(printf '─%.0s' $(seq 1 $box_width))╯"
    
    echo -e "${title_color}$border_top\e[0m"
    echo -e "${title_color}│\e[0m ${menu_color}$(msgf APP_NAME)\e[0m${title_color} │\e[0m"
    echo -e "${title_color}$border_bot\e[0m"
}

# --- Pure Bash display width function (not Unicode/CJK-aware) ---
display_width() {
  local input="$1"
  # Remove ANSI codes
  input=$(echo -e "$input" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
  # WARNING: This does not handle CJK/emoji width correctly!
  echo "${#input}"
}

# OS detection
OS_TYPE=$(uname)
case "$OS_TYPE" in
  Linux*)   OS=Linux;;
  Darwin*)  OS=Mac;;
  CYGWIN*|MINGW*|MSYS*) OS=Windows;;
  *)        OS="Unknown";;
esac

# Cross-platform helpers for system info
show_ip() {
  if [[ "$OS" == "Linux" ]]; then
    if command -v ip >/dev/null; then
      ip addr | grep 'inet '
    else
      ifconfig | grep 'inet '
    fi
  elif [[ "$OS" == "Mac" ]]; then
    ifconfig | grep 'inet '
  fi
}

show_mem() {
  if [[ "$OS" == "Linux" ]]; then
    free -h
  elif [[ "$OS" == "Mac" ]]; then
    vm_stat | awk 'NR==2{gsub(".","",$3); print "Free memory: "$3/256 " MB"}'
  fi
}

show_disk() {
  if [[ "$OS" == "Linux" || "$OS" == "Mac" ]]; then
    df -h
  fi
}

# --- Add Log Menu Options ---
add_log_menu_options() {
    menu_options+=("Log Tools")
    menu_plugins+=("SUBMENU:LOGTOOLS")
}

# Log Tools submenu handler
log_tools_menu() {
    while true; do
        clear
        echo "==== Log Tools ===="
        echo "1. Search logs by user"
        echo "2. Search logs by session"
        echo "3. Export logs by date"
        echo "4. View access/config changes"
        echo "5. Back"
        read -p "Select an option: " opt
        case $opt in
            1)
                read -p "Enter username: " user
                grep "user: $user" "$LOG_FILE" || echo "No logs for user $user."
                read -p "Press Enter to continue...";;
            2)
                read -p "Enter session ID: " sid
                grep "session: $sid" "$LOG_FILE" || echo "No logs for session $sid."
                read -p "Press Enter to continue...";;
            3)
                read -p "Enter date (YYYY-MM-DD): " date
                grep "$date" "$LOG_FILE" > "log_export_$date.txt"
                echo "Exported to log_export_$date.txt"
                read -p "Press Enter to continue...";;
            4)
                grep -E "action: session_start|action: config_change|action: language_change" "$LOG_FILE" || echo "No access/config logs."
                read -p "Press Enter to continue...";;
            5)
                break;;
            *)
                echo "Invalid option."; sleep 1;;
        esac
    done
}

# Main loop para menú y submenús
while true; do
    interrupt_count=0
    load_menu_section "$current_menu_section"
    if [[ "$current_menu_section" == "$DEFAULT_SECTION" ]]; then
        add_log_menu_options
    fi
    display_menu
    echo -ne "$(msgf PROMPT_SELECT) "
    read -rsn1 first
    # Navegación y salida inmediata con teclas
    if [[ "$first" == "n" || "$first" == "N" ]]; then
        total_options=${#menu_options[@]}
        total_pages=$(( (total_options + PAGE_SIZE - 1) / PAGE_SIZE ))
        (( current_page < total_pages )) && current_page=$((current_page+1))
        continue
    fi
    if [[ "$first" == "p" || "$first" == "P" ]]; then
        (( current_page > 1 )) && current_page=$((current_page-1))
        continue
    fi
    if [[ "$first" == "q" || "$first" == "Q" ]]; then
        log_event "INFO" "exit" "" "success" "$(msgf LOG_EVENT_EXIT)"
        cleanup_and_exit
    fi
    if [[ "$first" == $'\e' ]]; then
        read -rsn2 -t 0.1 rest
        if [[ "$rest" == "[C" ]]; then
            total_options=${#menu_options[@]}
            total_pages=$(( (total_options + PAGE_SIZE - 1) / PAGE_SIZE ))
            (( current_page < total_pages )) && current_page=$((current_page+1))
            continue
        elif [[ "$rest" == "[D" ]]; then
            (( current_page > 1 )) && current_page=$((current_page-1))
            continue
        fi
    fi
    # Si es número, mostrar el primer dígito y leer el resto de la línea
    if [[ "$first" =~ [0-9] ]]; then
        echo -n "$first"
        read -r rest
        choice="$first$rest"
        # Validar solo si la opción está en la página actual
        total_options=${#menu_options[@]}
        start_idx=$(( (current_page - 1) * PAGE_SIZE ))
        end_idx=$(( start_idx + PAGE_SIZE - 1 ))
        (( end_idx >= total_options )) && end_idx=$((total_options - 1))
        if validate_input "$choice"; then
            idx=$((choice-1))
            plugin_script="${menu_plugins[$idx]}"
            clear
            task_started "${menu_options[$idx]}"
            # --- Logging for menu selection ---
            if [[ "$plugin_script" == "__view_log__" ]]; then
                log_event "INFO" "view_log" "" "success" "$(msgf LOG_EVENT_VIEWED)"
                echo -e "\n$(msgf LOG_VIEW_TITLE)\n"
                if [[ -s "$LOG_FILE" ]]; then
                    less "$LOG_FILE"
                else
                    echo "$(msgf LOG_FILE_EMPTY)"
                    sleep 2
                fi
                task_ended "${menu_options[$idx]}"
                continue
            elif [[ "$plugin_script" == "__clear_log__" ]]; then
                log_event "WARNING" "clear_log" "" "success" "$(msgf LOG_EVENT_CLEARED)"
                > "$LOG_FILE"
                echo "$(msgf LOG_FILE_CLEARED)"
                sleep 1
                task_ended "${menu_options[$idx]}"
                continue
            elif [[ "$plugin_script" == "SUBMENU:LOGTOOLS" ]]; then
                log_tools_menu
                task_ended "${menu_options[$idx]}"
                continue
            fi
            log_event "INFO" "menu_select" "$plugin_script" "started" "$(msgf LOG_EVENT_MENU_SELECT "${menu_options[$idx]}")"
            # Normalize plugin_script and BACK_COMMAND to remove hidden characters and comments
            plugin_script=$(echo "$plugin_script" | cut -d'#' -f1 | tr -d '\r\n' | xargs)
            BACK_COMMAND=$(echo "$BACK_COMMAND" | cut -d'#' -f1 | tr -d '\r\n' | xargs)

            # --- Soporte para submenús ---
            if [[ "$plugin_script" =~ ^SUBMENU:(.+)$ ]]; then
                menu_stack+=("$current_menu_section")
                page_stack+=("$current_page")
                current_menu_section="SUBMENU:${BASH_REMATCH[1]}"
                current_page=1
                load_menu_section "$current_menu_section"
                task_ended "${menu_options[$idx]}"
                continue
            fi
            # Whitespace-insensitive BACK_COMMAND check
            if [[ "$plugin_script" == "$BACK_COMMAND" ]]; then
                if (( ${#menu_stack[@]} > 0 )); then
                    current_menu_section="${menu_stack[-1]}"
                    current_page="${page_stack[-1]}"
                    unset 'menu_stack[-1]' 'page_stack[-1]'
                    load_menu_section "$current_menu_section"
                fi
                task_ended "${menu_options[$idx]}"
                continue
            fi
            # --- Fin submenús ---
            plugin_script="$PLUGINS_DIR/$plugin_script"
            if [[ -x "$plugin_script" ]]; then
                "$plugin_script"
                if [[ $? -eq 0 && "${menu_plugins[$idx]}" == "$EXIT_COMMAND" ]]; then
                    log_event "INFO" "exit" "${menu_plugins[$idx]}" "success" "$(msgf LOG_EVENT_EXIT)"
                    cleanup_and_exit
                else
                    log_event "INFO" "plugin_run" "${menu_plugins[$idx]}" "success" "$(msgf LOG_EVENT_PLUGIN_RUN)"
                fi
            else
                # Only show plugin not found error if not BACK_COMMAND or SUBMENU
                if [[ ! "${menu_plugins[$idx]}" =~ ^SUBMENU: ]] && [[ "${menu_plugins[$idx]}" != "$BACK_COMMAND" ]]; then
                    log_event "ERROR" "plugin_not_found" "${menu_plugins[$idx]}" "failure" "$(msgf LOG_EVENT_PLUGIN_NOT_FOUND "$plugin_script")"
                    local error_color="\e[$(get_color_code "$ERROR_COLOR")m"
                    echo -e "${error_color}$(msgf PLUGIN_NOT_FOUND "$plugin_script")\e[0m"
                fi
            fi
            task_ended "${menu_options[$idx]}"
        fi
        echo -e -n "\e[1m$(msgf PROMPT_CONTINUE)\e[0m"
        read -s -n 1 -p ""
    fi
    # Si la entrada no es válida, simplemente vuelve a mostrar el prompt
    continue
done