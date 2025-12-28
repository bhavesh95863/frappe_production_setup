#!/bin/bash

# ==============================================================================
# Frappe Docker - Create Site Script
# ==============================================================================
# This script creates a new Frappe/ERPNext site
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Create New Site"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    echo "Please deploy first using:"
    echo "  ./scripts/deploy-production.sh"
    echo "  or"
    echo "  ./scripts/deploy-development.sh"
    exit 1
fi

# Check if services are running
if ! docker compose ps --status running | grep -q "backend"; then
    echo "❌ Services are not running!"
    echo "Please start services first:"
    echo "  docker compose up -d"
    exit 1
fi

# Load environment variables safely (avoid executing backticks)
if [ -f ".env" ]; then
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        # Export the variable
        export "$key=$value"
    done < <(grep -v '^[[:space:]]*$' .env)
fi

# Get site name
echo "📝 Enter site details:"
echo ""
read -p "Site name (e.g., erp.example.com or site1.localhost): " SITE_NAME

if [ -z "$SITE_NAME" ]; then
    echo "❌ Site name cannot be empty"
    exit 1
fi

# Get admin password
read -sp "Administrator password: " ADMIN_PASSWORD
echo ""

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ Admin password cannot be empty"
    exit 1
fi

# Get MariaDB root password from .env
DB_PASS="${DB_PASSWORD}"

if [ -z "$DB_PASS" ]; then
    read -sp "Database root password: " DB_PASS
    echo ""
fi

# Ask for apps to install
echo ""
echo "Install ERPNext? (recommended)"
read -p "(Y/n): " -n 1 -r INSTALL_ERPNEXT
echo ""

INSTALL_APPS=""
if [[ ! $INSTALL_ERPNEXT =~ ^[Nn]$ ]]; then
    INSTALL_APPS="--install-app erpnext"
fi

# Additional apps
echo ""
echo "Do you want to install additional apps? (e.g., hrms, payments)"
read -p "(y/N): " -n 1 -r INSTALL_ADDITIONAL
echo ""

if [[ $INSTALL_ADDITIONAL =~ ^[Yy]$ ]]; then
    echo "Enter app names separated by space (e.g., hrms payments):"
    read -r ADDITIONAL_APPS
    for app in $ADDITIONAL_APPS; do
        INSTALL_APPS="$INSTALL_APPS --install-app $app"
    done
fi

echo ""
echo "🚀 Creating site: $SITE_NAME"
echo "   Apps to install: ${INSTALL_APPS:-frappe only}"
echo ""

# Create the site
docker compose exec backend \
    bench new-site "$SITE_NAME" \
    --mariadb-root-password "$DB_PASS" \
    --admin-password "$ADMIN_PASSWORD" \
    $INSTALL_APPS \
    --force

echo ""
echo "=========================================="
echo "✅ Site created successfully!"
echo "=========================================="
echo ""
echo "Site: $SITE_NAME"
echo "Username: Administrator"
echo "Password: [your password]"
echo ""

# Set the site for bench commands
echo "🔧 Setting as current site..."
docker compose exec backend bench use "$SITE_NAME"

echo ""
echo "🌐 Access your site:"
if [ -n "$SITES" ]; then
    echo "  https://$SITE_NAME"
else
    echo "  http://localhost:${HTTP_PUBLISH_PORT:-8080}"
fi
echo ""
echo "📝 Common operations:"
echo "  - Backup site: ./scripts/backup.sh"
echo "  - Access shell: docker compose exec backend bash"
echo "  - View logs: docker compose logs -f backend"
echo ""
