#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

# Create example Dockerfiles directory
mkdir -p "$SCRIPT_DIR/examples"

# Create a simple nginx Dockerfile
cat > "$SCRIPT_DIR/examples/nginx.Dockerfile" << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create index.html for nginx
cat > "$SCRIPT_DIR/examples/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Test Page</title>
</head>
<body>
    <h1>Hello from Docker!</h1>
    <p>This page was served from a custom Docker image.</p>
</body>
</html>
EOF

# Create a Python Flask Dockerfile
cat > "$SCRIPT_DIR/examples/python.Dockerfile" << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# Create requirements.txt for Python app
cat > "$SCRIPT_DIR/examples/requirements.txt" << 'EOF'
Flask==2.0.1
EOF

# Create app.py for Python app
cat > "$SCRIPT_DIR/examples/app.py" << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return '<h1>Hello from Python Flask!</h1><p>This is served from a custom Docker image.</p>'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

print_box \
    "$(print_colored "$SUCCESS_COLOR" "✅ Example Dockerfiles created!")" \
    "$(print_colored "$INFO_COLOR" "Location: $SCRIPT_DIR/examples/")" \
    "$(print_colored "$MENU_COLOR" "• nginx.Dockerfile - Simple nginx web server")" \
    "$(print_colored "$MENU_COLOR" "• python.Dockerfile - Python Flask web app")" \
    "$(print_colored "$INFO_COLOR" "Use these with the 'Build Image' feature to test custom image building.")" 