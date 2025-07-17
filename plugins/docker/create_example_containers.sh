#!/bin/bash

# Create nginx container
if ! docker ps -a --format '{{.Names}}' | grep -q '^nginx_server$'; then
  docker run -d --name nginx_server -p 8080:80 nginx:latest
else
  echo "nginx_server already exists. Skipping."
fi

# Create postgres container
if ! docker ps -a --format '{{.Names}}' | grep -q '^postgres_db$'; then
  docker run -d --name postgres_db -e POSTGRES_PASSWORD=example -p 5432:5432 postgres:15
else
  echo "postgres_db already exists. Skipping."
fi

# Create alpine container
if ! docker ps -a --format '{{.Names}}' | grep -q '^alpine_test$'; then
  docker run -d --name alpine_test alpine:latest tail -f /dev/null
else
  echo "alpine_test already exists. Skipping."
fi

echo "Example containers created or already exist: nginx_server, postgres_db, alpine_test" 