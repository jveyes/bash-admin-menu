#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

# Create containers that use volumes
containers=(
    "nginx_vol:nginx:latest:app_data:/usr/share/nginx/html"
    "postgres_vol:postgres:15:db_data:/var/lib/postgresql/data"
    "alpine_vol:alpine:latest:config_data:/config"
)

for container_info in "${containers[@]}"; do
    IFS=':' read -r name image volume mount_path <<< "$container_info"
    
    if ! docker ps -a --format '{{.Names}}' | grep -q "^$name$"; then
        case $name in
            "nginx_vol")
                docker run -d --name "$name" -v "$volume:$mount_path" -p 8081:80 "$image"
                ;;
            "postgres_vol")
                docker run -d --name "$name" -v "$volume:$mount_path" -e POSTGRES_PASSWORD=example -p 5433:5432 "$image"
                ;;
            "alpine_vol")
                docker run -d --name "$name" -v "$volume:$mount_path" "$image" tail -f /dev/null
                ;;
        esac
        print_box "$(print_colored "$SUCCESS_COLOR" "Created container with volume: $name using $volume")"
    else
        print_box "$(print_colored "$WARNING_COLOR" "Container '$name' already exists. Skipping.")"
    fi
done

print_box "$(print_colored "$INFO_COLOR" "Example containers with volumes created successfully!")" 