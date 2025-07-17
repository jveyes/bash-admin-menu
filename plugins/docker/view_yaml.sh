#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

clear
# Print a title in a frame above the YAML file list
print_box "$(print_colored "$TITLE_COLOR" "View/Pretty-Print YAML")"
# Helper: Print a colored box for validation results
print_validation_box() {
    local status="$1"
    local message="$2"
    local color
    if [ "$status" = "success" ]; then
        color="$SUCCESS_COLOR"
    else
        color="$ERROR_COLOR"
    fi
    print_box "$(print_colored "$color" "YAML Validation Result:")" "$message"
}

# Search for YAML files in the project
files=()
while IFS= read -r f; do files+=("$f"); done < <(find "$PWD" -type f \( -iname '*.yml' -o -iname '*.yaml' \))
if [ ${#files[@]} -eq 0 ]; then
    print_box "$(print_colored "$WARNING_COLOR" "No YAML files found in the project.")"
    read -p "Presiona Enter para continuar..."
    exit 1
fi

# Prepare arrays for filename and relative path
fnames=()
relpaths=()
for f in "${files[@]}"; do
    fnames+=("$(basename "$f")")
    relpaths+=("$(realpath --relative-to="$PWD" "$f")")
done

# Calculate widths for alignment
max_fname=0
max_rpath=0
for v in "${fnames[@]}"; do [ ${#v} -gt $max_fname ] && max_fname=${#v}; done
for v in "${relpaths[@]}"; do [ ${#v} -gt $max_rpath ] && max_rpath=${#v}; done

# Build arguments for print_box (YAML file list)
box_lines=("$(print_colored "$INFO_COLOR" "Available YAML files:")")
for i in "${!files[@]}"; do
    num_col=$(print_colored "$INFO_COLOR" "$(printf "%2d" $((i+1)))")
    fname_col=$(print_colored "$SUCCESS_COLOR" "$(printf "%-${max_fname}s" "${fnames[$i]}")")
    rpath_col=$(print_colored "$MENU_COLOR" "$(printf "%-${max_rpath}s" "${relpaths[$i]}")")
    box_lines+=("$num_col. $fname_col  $rpath_col")
done
print_box "${box_lines[@]}"

# File selection (no extra confirmation)
while true; do
    read -p "Enter number [1-${#files[@]}]: " idx
    if [[ $idx =~ ^[0-9]+$ ]] && [ $idx -ge 1 ] && [ $idx -le ${#files[@]} ]; then
        yaml_file="${files[$((idx-1))]}"
        break
    else
        print_box "$(print_colored "$ERROR_COLOR" "Invalid selection.")"
    fi
done

# Function: Show action menu for the selected file
acciones_yaml() {
    while true; do
        clear
        # Show selected file path (explanation)
        print_box "$(print_colored "$INFO_COLOR" "Archivo seleccionado:")" "$(print_colored "$MENU_COLOR" "$yaml_file")"
        echo
        # Show YAML content with line numbers in a merged frame
        if command -v yq &>/dev/null; then
            content=$(yq . "$yaml_file")
        else
            content=$(python3 -c 'import sys, yaml, pprint; pprint.pprint(yaml.safe_load(sys.stdin))' < "$yaml_file")
        fi
        mapfile -t content_lines < <(echo "$content")
        num_lines=${#content_lines[@]}
        max_line_len=0
        for l in "${content_lines[@]}"; do [ ${#l} -gt $max_line_len ] && max_line_len=${#l}; done
        header_text="Contenido del archivo (formato legible):"
        header_len=${#header_text}
        # Use the max of header and content for the frame width
        frame_width=$max_line_len
        [ $header_len -gt $frame_width ] && frame_width=$header_len
        # Add 20% more spaces for padding
        extra_pad=$(( (frame_width + 4) / 5 ))
        frame_width=$((frame_width + extra_pad))
        max_num_len=3
        header=$(print_colored "$INFO_COLOR" "$header_text")
        # Top border
        printf "\e[36m┌%s┬%s┐\e[0m\n" "$(printf '─%.0s' $(seq 1 $max_num_len))" "$(printf '─%.0s' $(seq 1 $frame_width))"
        # Header row (spanning both columns, perfectly aligned)
        printf "\e[36m│%*s│%-*s│\e[0m\n" $max_num_len "#" "$frame_width" "$header_text"
        # Separator
        printf "\e[36m├%s┼%s┤\e[0m\n" "$(printf '─%.0s' $(seq 1 $max_num_len))" "$(printf '─%.0s' $(seq 1 $frame_width))"
        # Content rows
        for ((i=0; i<num_lines; i++)); do
            printf "\e[36m│%*d│%-*s│\e[0m\n" $max_num_len $((i+1)) $frame_width "${content_lines[$i]}"
        done
        # Bottom border
        printf "\e[36m└%s┴%s┘\e[0m\n" "$(printf '─%.0s' $(seq 1 $max_num_len))" "$(printf '─%.0s' $(seq 1 $frame_width))"
        echo
        # Improved action menu in a box (no emojis, no explanations)
        menu_lines=(
            "$(print_colored "$TITLE_COLOR" "¿Qué deseas hacer con este archivo?")"
            ""
            "$(print_colored "$SUCCESS_COLOR" " 1. Validar YAML   ")"
            "$(print_colored "$WARNING_COLOR" " 2. Editar YAML   ")"
            "$(print_colored "$MENU_COLOR" " q. Volver        ")"
        )
        print_box "${menu_lines[@]}"
        read -p "Selecciona una opción: " action
        case $action in
            1)
                clear
                # Call validate_yaml.sh directly to preserve frame formatting
                bash "$SCRIPT_DIR/validate_yaml.sh" "$yaml_file"
                read -p "Presiona Enter para volver al menú de acciones..."
                ;;
            2)
                clear
                bash "$SCRIPT_DIR/edit_yaml.sh" "$yaml_file"
                read -p "Presiona Enter para volver al menú de acciones..."
                ;;
            q|Q)
                break
                ;;
            *)
                print_box "$(print_colored "$ERROR_COLOR" "Opción inválida. Intenta de nuevo.")"
                ;;
        esac
    done
}

# Show the action menu for the selected file
acciones_yaml 