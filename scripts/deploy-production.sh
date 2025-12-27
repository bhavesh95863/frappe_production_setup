#!/bin/bash

# ==============================================================================
# Frappe Docker - Production Deployment Script
# ==============================================================================
# This script deploys Frappe/ERPNext in production mode with SSL support
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Production Deployment"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "Please create .env file from example:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Load environment variables (safely, without executing backticks)
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ $key =~ ^#.*$ ]] && continue
    [[ -z $key ]] && continue
    # Export variable
    export "$key=$value"
done < <(grep -v '^\s*$' .env)

# Validate required variables
if [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "YourStrongPasswordHere123!" ]; then
    echo "❌ Please set a strong DB_PASSWORD in .env file"
    exit 1
fi

if [ -z "$LETSENCRYPT_EMAIL" ] || [ "$LETSENCRYPT_EMAIL" = "admin@example.com" ]; then
    echo "⚠️  Warning: LETSENCRYPT_EMAIL not properly configured in .env"
    echo "SSL certificates will not work without a valid email."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if frappe_docker exists
if [ ! -d "../frappe_docker" ]; then
    echo "❌ frappe_docker repository not found!"
    echo "Cloning frappe_docker repository..."
    cd ..
    git clone https://github.com/frappe/frappe_docker.git
    cd "$PROJECT_DIR"
fi

echo "✅ Configuration loaded"
echo ""
echo "📋 Deployment Configuration:"
echo "  ERPNext Version: ${ERPNEXT_VERSION}"
echo "  Database Password: ********"
echo "  SSL Email: ${LETSENCRYPT_EMAIL}"
echo "  Sites: ${SITES}"
echo "  Custom Image: ${CUSTOM_IMAGE:-frappe/erpnext}"
echo "  Custom Tag: ${CUSTOM_TAG:-$ERPNEXT_VERSION}"
echo ""

read -p "🚀 Ready to deploy? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

echo ""
echo "🔧 Generating docker-compose.yml..."

# Generate compose file with production overrides
docker compose \
    --env-file .env \
    -f ../frappe_docker/compose.yaml \
    -f ../frappe_docker/overrides/compose.mariadb.yaml \
    -f ../frappe_docker/overrides/compose.redis.yaml \
    -f ../frappe_docker/overrides/compose.https.yaml \
    config > docker-compose.yml

echo "✅ docker-compose.yml generated"

# Create required directories
echo "📁 Creating required directories..."
mkdir -p backups

echo ""
echo "🚀 Starting services..."
docker compose up -d

echo ""
echo "=========================================="
echo "✅ Production deployment completed!"
echo "=========================================="
echo ""
echo "Services are starting up. This may take a few minutes."
echo ""
echo "📊 Check status:"
echo "  docker compose ps"
echo ""
echo "📝 View logs:"
echo "  docker compose logs -f"
echo ""
echo "🌐 Next steps:"
echo "1. Wait for all services to be healthy (check with: docker compose ps)"
echo "2. Create your first site: ./scripts/create-site.sh"
echo "3. Access your site at: https://${SITES}"
echo ""
echo "⚠️  SSL certificates will be automatically generated on first access."
echo "Make sure your domain DNS points to this server!"
echo ""
