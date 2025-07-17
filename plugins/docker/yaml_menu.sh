#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

# Human-readable size function
human_size() {
    local size=$1
    if [ "$size" -lt 1024 ]; then
        echo "${size} B"
    elif [ "$size" -lt $((1024*1024)) ]; then
        printf '%.1f KB' "$(echo "$size/1024" | bc -l)"
    elif [ "$size" -lt $((1024*1024*1024)) ]; then
        printf '%.1f MB' "$(echo "$size/1024/1024" | bc -l)"
    else
        printf '%.1f GB' "$(echo "$size/1024/1024/1024" | bc -l)"
    fi
}

# Reusable function to print the YAML file table (no prompt)
list_yaml_files_table() {
    clear
    # Print a title in a frame above the table
    print_box "$(print_colored "$TITLE_COLOR" "List YAML Files")"
    local files=()
    while IFS= read -r f; do files+=("$f"); done < <(find "$SCRIPT_DIR/../.." -type f \( -iname '*.yml' -o -iname '*.yaml' \))
    if [ ${#files[@]} -eq 0 ]; then
        print_box "$(print_colored "$WARNING_COLOR" "No YAML files found in the project.")"
        return 1
    fi
    # Prepare arrays for each column
    local ids=()
    local fnames=()
    local fpaths=()
    local fsizes=()
    local flines=()
    local fmods=()
    for i in "${!files[@]}"; do
        local f="${files[$i]}"
        ids+=("$((i+1))")
        fnames+=("$(basename "$f")")
        fpaths+=("$(realpath --relative-to="$PWD" "$f")")
        fsizes+=("$(human_size $(stat -c %s "$f"))")
        flines+=("$(wc -l < "$f" | tr -d ' ')" )
        fmods+=("$(stat -c '%y' "$f" | cut -c1-16)")
    done
    # Add header values for width calculation
    ids+=("Id")
    fnames+=("Filename")
    fpaths+=("Path")
    fsizes+=("Size")
    flines+=("Lines")
    fmods+=("Modified")
    # Calculate max width for each column
    local max_id=0; local max_fname=0; local max_path=0; local max_size=0; local max_lines=0; local max_mod=0;
    for v in "${ids[@]}"; do [ ${#v} -gt $max_id ] && max_id=${#v}; done
    for v in "${fnames[@]}"; do [ ${#v} -gt $max_fname ] && max_fname=${#v}; done
    for v in "${fpaths[@]}"; do [ ${#v} -gt $max_path ] && max_path=${#v}; done
    for v in "${fsizes[@]}"; do [ ${#v} -gt $max_size ] && max_size=${#v}; done
    for v in "${flines[@]}"; do [ ${#v} -gt $max_lines ] && max_lines=${#v}; done
    for v in "${fmods[@]}"; do [ ${#v} -gt $max_mod ] && max_mod=${#v}; done
    # Remove header from arrays for row printing
    unset 'ids[${#ids[@]}-1]' 'fnames[${#fnames[@]}-1]' 'fpaths[${#fpaths[@]}-1]' 'fsizes[${#fsizes[@]}-1]' 'flines[${#flines[@]}-1]' 'fmods[${#fmods[@]}-1]'
    # Prepare table header with dynamic widths
    local idx_head=$(print_colored "$INFO_COLOR" "$(printf "%-${max_id}s" "Id")")
    local fname_head=$(print_colored "$SUCCESS_COLOR" "$(printf "%-${max_fname}s" "Filename")")
    local fpath_head=$(print_colored "$MENU_COLOR" "$(printf "%-${max_path}s" "Path")")
    local fsize_head=$(print_colored "$WARNING_COLOR" "$(printf "%${max_size}s" "Size")")
    local flines_head=$(print_colored "$INFO_COLOR" "$(printf "%${max_lines}s" "Lines")")
    local fmtime_head=$(print_colored "$INFO_COLOR" "$(printf "%-${max_mod}s" "Modified")")
    local header="$idx_head | $fname_head | $fpath_head | $fsize_head | $flines_head | $fmtime_head"
    local rows=()
    for i in "${!files[@]}"; do
        idx_col=$(print_colored "$INFO_COLOR" "$(printf "%-${max_id}d" $((i+1)))")
        fname_col=$(print_colored "$SUCCESS_COLOR" "$(printf "%-${max_fname}s" "${fnames[$i]}")")
        fpath_col=$(print_colored "$MENU_COLOR" "$(printf "%-${max_path}s" "${fpaths[$i]}")")
        fsize_col=$(print_colored "$WARNING_COLOR" "$(printf "%${max_size}s" "${fsizes[$i]}")")
        flines_col=$(print_colored "$INFO_COLOR" "$(printf "%${max_lines}s" "${flines[$i]}")")
        fmtime_col=$(print_colored "$INFO_COLOR" "$(printf "%-${max_mod}s" "${fmods[$i]}")")
        rows+=("$idx_col | $fname_col | $fpath_col | $fsize_col | $flines_col | $fmtime_col")
    done
    print_box "$header" "${rows[@]}"
}

show_yaml_menu() {
    clear
    print_box \
        "$(print_colored "$TITLE_COLOR" "YAML Management")" \
        "$(print_colored "$INFO_COLOR" "Manage and manipulate YAML files")"
    echo
    echo "1. 📂 List YAML Files"
    echo "2. 👀 View/Pretty-Print YAML"
    echo "3. ✅ Validate YAML"
    echo "4. ✏️  Edit YAML"
    echo "5. 🔍 Search/Query YAML"
    echo "6. 🔄 Convert YAML <-> JSON"
    echo "7. 🧹 Lint YAML"
    echo "8. ➕ Merge YAML Files"
    echo "9. ➗ Split YAML File"
    echo "10. 📝 Generate YAML from Template"
    echo "11. 🆚 Diff YAML Files"
    echo "12. 🚀 Apply YAML (Compose/K8s)"
    echo
    echo "q. 🔙 Back"
    echo
}

while true; do
    show_yaml_menu
    read -p "Select an option: " choice
    case $choice in
        1) list_yaml_files_table; read -p "Press Enter to continue...";;
        2) bash "$SCRIPT_DIR/view_yaml.sh";;
        3) bash "$SCRIPT_DIR/validate_yaml.sh"; read -p "Press Enter to continue...";;
        4) bash "$SCRIPT_DIR/edit_yaml.sh"; read -p "Press Enter to continue...";;
        5) bash "$SCRIPT_DIR/query_yaml.sh"; read -p "Press Enter to continue...";;
        6) bash "$SCRIPT_DIR/convert_yaml_json.sh"; read -p "Press Enter to continue...";;
        7) bash "$SCRIPT_DIR/lint_yaml.sh"; read -p "Press Enter to continue...";;
        8) bash "$SCRIPT_DIR/merge_yaml.sh"; read -p "Press Enter to continue...";;
        9) bash "$SCRIPT_DIR/split_yaml.sh"; read -p "Press Enter to continue...";;
        10) bash "$SCRIPT_DIR/generate_yaml.sh"; read -p "Press Enter to continue...";;
        11) bash "$SCRIPT_DIR/diff_yaml.sh"; read -p "Press Enter to continue...";;
        12) bash "$SCRIPT_DIR/apply_yaml.sh"; read -p "Press Enter to continue...";;
        q|Q) break;;
        *) print_colored "$ERROR_COLOR" "❌ Invalid option!"; sleep 1;;
    esac
done 