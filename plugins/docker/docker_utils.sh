#!/bin/bash

# Color variables for output
TITLE_COLOR="blue"
MENU_COLOR="white"
ERROR_COLOR="red"
SUCCESS_COLOR="green"
WARNING_COLOR="yellow"
INFO_COLOR="cyan"

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

print_colored() {
    local color="$1"
    local text="$2"
    local color_code=$(get_color_code "$color")
    echo -e "\e[${color_code}m${text}\e[0m"
}

# Helper: Select a YAML file from all found in the project
select_yaml_file() {
    local files=()
    while IFS= read -r f; do files+=("$f"); done < <(find "$PWD" -type f \( -iname '*.yml' -o -iname '*.yaml' \))
    if [ ${#files[@]} -eq 0 ]; then
        print_box "$(print_colored "$WARNING_COLOR" "No YAML files found in the project.")"
        return 1
    fi
    while true; do
        print_box "$(print_colored "$INFO_COLOR" "Available YAML files:")"
        for i in "${!files[@]}"; do
            printf "  %2d. %s\n" $((i+1)) "${files[$i]}"
        done
        echo
        local idx
        read -p "Enter number [1-${#files[@]}]: " idx
        if [[ $idx =~ ^[0-9]+$ ]] && [ $idx -ge 1 ] && [ $idx -le ${#files[@]} ]; then
            local selected="${files[$((idx-1))]}"
            read -p "Use this file? (full path: $selected) [y/n]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo "$selected"
                return 0
            fi
        else
            print_box "$(print_colored "$ERROR_COLOR" "Invalid selection.")"
        fi
    done
}

print_box() {
    local lines=()
    # Split all input into individual lines
    for arg in "$@"; do
        while IFS= read -r l; do lines+=("$l"); done <<<"$arg"
    done
    local maxlen=0
    local maxwidth=200  # Set max width for the box
    local line visible_line len
    # Calculate maxlen based on visible (non-ANSI) length, but cap at maxwidth
    for line in "${lines[@]}"; do
        visible_line=$(echo -e "$line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        len=${#visible_line}
        (( len > maxlen )) && maxlen=$len
    done
    (( maxlen > maxwidth )) && maxlen=$maxwidth
    local border_top="╭$(printf '─%.0s' $(seq 1 $((maxlen+2))))╮"
    local border_bot="╰$(printf '─%.0s' $(seq 1 $((maxlen+2))))╯"
    echo -e "$border_top"
    for line in "${lines[@]}"; do
        # Remove any box-drawing characters from nested boxes
        line=$(echo "$line" | sed 's/[╭╮╰╯│─]//g')
        visible_line=$(echo -e "$line" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        local first=1
        while [ ${#visible_line} -gt $maxwidth ]; do
            part="${visible_line:0:$maxwidth}"
            if [ $first -eq 1 ]; then
                printf "│ %s │\n" "$part"
                first=0
            else
                printf "│ … %-*s │\n" $((maxlen-2)) "${part:2}"
            fi
            visible_line="${visible_line:$maxwidth}"
            line="${line:$maxwidth}"
        done
        len=${#visible_line}
        printf "│ %b%*s │\n" "$line" $((maxlen-len)) ""
    done
    echo -e "$border_bot"
} 