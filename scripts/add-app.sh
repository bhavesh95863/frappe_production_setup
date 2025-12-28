#!/bin/bash

# ==============================================================================
# Frappe Docker - Add App to Existing Deployment
# ==============================================================================
# This script adds a new app to an already running production environment
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Add App"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    echo "Please deploy first using: ./scripts/deploy-production.sh"
    exit 1
fi

# Check if services are running
if ! docker compose ps --status running | grep -q "backend"; then
    echo "❌ Services are not running!"
    echo "Please start services first: docker compose up -d"
    exit 1
fi

# Check if apps.json exists
if [ ! -f "apps.json" ]; then
    echo "❌ apps.json not found!"
    exit 1
fi

echo "📋 Current apps in apps.json:"
echo ""
cat apps.json
echo ""
echo "=========================================="
echo ""

echo "📝 Enter new app details:"
echo ""
read -p "App repository URL: " APP_URL

if [ -z "$APP_URL" ]; then
    echo "❌ Repository URL cannot be empty"
    exit 1
fi

read -p "Branch (default: version-15): " APP_BRANCH
APP_BRANCH=${APP_BRANCH:-version-15}

echo ""
echo "⚠️  IMPORTANT: Before adding apps:"
echo "1. Make sure you have a recent backup"
echo "2. This will rebuild the Docker image"
echo "3. All containers will be restarted"
echo "4. Sites will be briefly unavailable"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Backup current apps.json
cp apps.json apps.json.backup
echo "✅ Backed up apps.json to apps.json.backup"

# Add new app to apps.json
echo "📝 Adding new app to apps.json..."

# Parse the JSON and add new app (using python if available, otherwise manual)
if command -v python3 &> /dev/null; then
    python3 << EOF
import json

with open('apps.json', 'r') as f:
    data = json.load(f)

new_app = {
    "url": "$APP_URL",
    "branch": "$APP_BRANCH"
}

data.append(new_app)

with open('apps.json', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')

print("✅ Added app to apps.json")
EOF
else
    echo "❌ Python3 not found. Please manually add the app to apps.json:"
    echo '{'
    echo '  "url": "'$APP_URL'",'
    echo '  "branch": "'$APP_BRANCH'"'
    echo '}'
    exit 1
fi

echo ""
echo "📋 Updated apps.json:"
cat apps.json
echo ""

# Rebuild the image
echo "🔨 Rebuilding Docker image with new app..."
echo "This may take several minutes..."
echo ""

./scripts/build-image.sh

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Image build failed!"
    echo "Restoring original apps.json..."
    mv apps.json.backup apps.json
    exit 1
fi

# Stop services
echo ""
echo "⏸️  Stopping services..."
docker compose down

# Start services with new image
echo ""
echo "🚀 Starting services with updated image..."
docker compose up -d

# Wait for backend to be ready
echo ""
echo "⏳ Waiting for services to start..."
sleep 15

# Get list of sites
echo ""
echo "📋 Available sites:"
SITES_LIST=$(docker compose exec -T backend bash -c "ls -1 sites/*/site_config.json 2>/dev/null | cut -d'/' -f2" 2>/dev/null || echo "")

if [ -z "$SITES_LIST" ]; then
    echo "❌ No sites found!"
    echo ""
    echo "✅ Image updated successfully, but no sites to install app on."
    echo "Create a site using: ./scripts/create-site.sh"
    exit 0
fi

echo "$SITES_LIST"
echo ""

read -p "Install app on which site? (or 'all' for all sites, 'skip' to skip): " SITE_CHOICE

if [ "$SITE_CHOICE" = "skip" ]; then
    echo "✅ Image updated. You can manually install the app later using:"
    echo "   docker compose exec backend bench --site <site-name> install-app <app-name>"
    exit 0
fi

# Extract app name from URL (last part before .git)
APP_NAME=$(basename "$APP_URL" .git)

if [ "$SITE_CHOICE" = "all" ]; then
    echo ""
    echo "📦 Installing app on all sites..."
    for SITE in $SITES_LIST; do
        echo ""
        echo "Installing on: $SITE"
        docker compose exec -T backend bench --site "$SITE" install-app "$APP_NAME" || {
            echo "⚠️  Failed to install on $SITE (may already be installed or error occurred)"
        }
    done
else
    echo ""
    echo "📦 Installing app: $APP_NAME on site: $SITE_CHOICE"
    docker compose exec -T backend bench --site "$SITE_CHOICE" install-app "$APP_NAME"
fi

# Cleanup backup
rm -f apps.json.backup

echo ""
echo "=========================================="
echo "✅ App Added Successfully!"
echo "=========================================="
echo ""
echo "App: $APP_NAME"
echo "From: $APP_URL"
echo "Branch: $APP_BRANCH"
echo ""
echo "To verify installation:"
echo "  docker compose exec backend bench --site <site-name> list-apps"
echo ""
