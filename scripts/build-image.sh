#!/bin/bash

# ==============================================================================
# Frappe Docker - Build Custom Image Script
# ==============================================================================
# This script builds a custom Frappe/ERPNext image with apps from apps.json
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Build Custom Image"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if apps.json exists
if [ ! -f "apps.json" ]; then
    echo "❌ apps.json not found!"
    echo "Please create apps.json file in the project root."
    echo ""
    echo "Example apps.json:"
    echo '['
    echo '  {'
    echo '    "url": "https://github.com/frappe/erpnext",'
    echo '    "branch": "version-15"'
    echo '  }'
    echo ']'
    exit 1
fi

# Load environment variables (safely, without executing backticks)
if [ -f ".env" ]; then
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        # Export variable
        export "$key=$value"
    done < <(grep -v '^\s*$' .env)
    echo "✅ Loaded configuration from .env"
else
    echo "⚠️  .env file not found, using defaults"
    FRAPPE_VERSION="version-15"
fi

# Display apps.json content
echo ""
echo "📋 Apps to install:"
cat apps.json | grep -E '(url|branch)' || cat apps.json
echo ""

# Generate base64 encoded apps.json
echo "🔧 Encoding apps.json..."
APPS_JSON_BASE64=$(base64 -w 0 apps.json)

# Check if frappe_docker exists
if [ ! -d "../frappe_docker" ]; then
    echo "📥 Cloning frappe_docker repository..."
    cd ..
    git clone https://github.com/frappe/frappe_docker.git
    cd "$PROJECT_DIR"
fi

# Build arguments
FRAPPE_PATH="${FRAPPE_PATH:-https://github.com/frappe/frappe}"
FRAPPE_BRANCH="${FRAPPE_VERSION:-version-15}"
IMAGE_NAME="${CUSTOM_IMAGE:-custom-frappe}"
IMAGE_TAG="${CUSTOM_TAG:-latest}"

echo ""
echo "🐳 Build Configuration:"
echo "  Frappe Path: $FRAPPE_PATH"
echo "  Frappe Branch: $FRAPPE_BRANCH"
echo "  Image Name: $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Build the image
echo "🏗️  Building Docker image (this may take 10-30 minutes)..."
echo ""

docker build \
  --build-arg=FRAPPE_PATH="$FRAPPE_PATH" \
  --build-arg=FRAPPE_BRANCH="$FRAPPE_BRANCH" \
  --build-arg=APPS_JSON_BASE64="$APPS_JSON_BASE64" \
  --tag="$IMAGE_NAME:$IMAGE_TAG" \
  --file=../frappe_docker/images/layered/Containerfile \
  ../frappe_docker

echo ""
echo "=========================================="
echo "✅ Image built successfully!"
echo "=========================================="
echo ""
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "To use this custom image, update your .env file:"
echo "  CUSTOM_IMAGE=$IMAGE_NAME"
echo "  CUSTOM_TAG=$IMAGE_TAG"
echo ""
echo "Next step: Deploy with ./scripts/deploy-production.sh"
echo ""
