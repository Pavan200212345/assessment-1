#!/bin/bash

set -e

echo "======================================"
echo " Deploying Employee Management System"
echo "======================================"

APP_DIR="/opt/employee-management"
REPO_DIR="$APP_DIR/repository"

REPO_URL="https://github.com/Pavan200212345/assessment-1.git"
GHCR_IMAGE="ghcr.io/pavan200212345/employee-backend:latest"

echo "[1/8] Checking Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    echo "Run server1_setup.sh first."
    exit 1
fi

echo "[2/8] Preparing application directory..."

sudo mkdir -p "$APP_DIR"
sudo chown -R "$USER":"$USER" "$APP_DIR"

echo "[3/8] Getting latest frontend code..."

if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    git pull origin main
else
    git clone "$REPO_URL" "$REPO_DIR"
fi

echo "[4/8] Checking frontend files..."

if [ ! -f "$REPO_DIR/app/frontend/index.html" ]; then
    echo "ERROR: index.html not found."
    exit 1
fi

if [ ! -f "$REPO_DIR/app/frontend/app.js" ]; then
    echo "ERROR: app.js not found."
    exit 1
fi

if [ ! -f "$REPO_DIR/app/frontend/style.css" ]; then
    echo "ERROR: style.css not found."
    exit 1
fi

echo "[5/8] Checking environment file..."

if [ ! -f "$APP_DIR/.env" ]; then
    echo "ERROR: $APP_DIR/.env not found."
    echo "Create the PostgreSQL connection configuration first."
    exit 1
fi

echo "[6/8] Pulling latest backend image..."

sudo docker pull "$GHCR_IMAGE"

echo "[7/8] Creating Docker network and Nginx configuration..."

sudo docker network create employee-network 2>/dev/null || true

sudo mkdir -p "$APP_DIR/nginx"

sudo tee "$APP_DIR/nginx/nginx.conf" > /dev/null <<'EOF'
events {}

http {

    server {

        listen 80;

        server_name _;

        location / {

            root /usr/share/nginx/html;

            index index.html;

            try_files $uri $uri/ /index.html;
        }

        location /api/ {

            proxy_pass http://employee-backend:8000;

            proxy_set_header Host $host;

            proxy_set_header X-Real-IP $remote_addr;

            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

echo "[8/8] Starting application containers..."

sudo docker rm -f employee-backend 2>/dev/null || true
sudo docker rm -f employee-nginx 2>/dev/null || true

sudo docker run -d \
    --name employee-backend \
    --network employee-network \
    --restart unless-stopped \
    --env-file "$APP_DIR/.env" \
    "$GHCR_IMAGE"

sudo docker run -d \
    --name employee-nginx \
    --network employee-network \
    --restart unless-stopped \
    -p 80:80 \
    -v "$APP_DIR/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
    -v "$REPO_DIR/app/frontend:/usr/share/nginx/html:ro" \
    nginx:alpine

echo ""
echo "======================================"
echo " Deployment completed successfully"
echo "======================================"

echo ""
echo "Running containers:"
sudo docker ps

echo ""
echo "Application:"
echo "http://SERVER1_PUBLIC_IP"