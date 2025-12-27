#!/bin/bash

################################################################################
# Frappe Docker - Complete Cleanup Script
# 
# This script removes Docker containers, images, volumes, and optionally
# Docker itself from the server. USE WITH CAUTION!
#
# Usage: bash cleanup.sh [OPTIONS]
# Options:
#   --remove-data       Delete all site data (DESTRUCTIVE!)
#   --remove-images     Remove Docker images
#   --remove-docker     Uninstall Docker completely
#   --force             Skip confirmations (DANGEROUS!)
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Default options
REMOVE_DATA=false
REMOVE_IMAGES=false
REMOVE_DOCKER=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-data)
            REMOVE_DATA=true
            shift
            ;;
        --remove-images)
            REMOVE_IMAGES=true
            shift
            ;;
        --remove-docker)
            REMOVE_DOCKER=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo ""
            echo "Usage: bash cleanup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --remove-data       Delete all site data (DESTRUCTIVE!)"
            echo "  --remove-images     Remove Docker images"
            echo "  --remove-docker     Uninstall Docker completely"
            echo "  --force             Skip confirmations (DANGEROUS!)"
            echo ""
            exit 1
            ;;
    esac
done

FRAPPE_DOCKER_DIR="/home/frappe/frappe_docker"

################################################################################
# Display warning
################################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║              ⚠️  DOCKER CLEANUP UTILITY  ⚠️                   ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
log_warn "This script will remove Docker setup from this server!"
echo ""
echo "Actions to be performed:"
echo "  • Stop all running containers"
echo "  • Remove containers and networks"
if [ "$REMOVE_DATA" = true ]; then
    echo "  • ${RED}DELETE ALL SITE DATA (DESTRUCTIVE!)${NC}"
fi
if [ "$REMOVE_IMAGES" = true ]; then
    echo "  • Remove Docker images"
fi
if [ "$REMOVE_DOCKER" = true ]; then
    echo "  • ${RED}UNINSTALL DOCKER COMPLETELY${NC}"
fi
echo ""

if [ "$FORCE" = false ]; then
    echo "Type 'yes' to continue or anything else to cancel:"
    read -r response
    if [ "$response" != "yes" ]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
fi

################################################################################
# Step 1: Stop and remove containers
################################################################################

log_step "1/5 Stopping and removing containers..."

if [ -d "$FRAPPE_DOCKER_DIR" ]; then
    cd "$FRAPPE_DOCKER_DIR"
    
    # Check if docker-compose.yml exists
    if [ -f "docker-compose.yml" ]; then
        log_info "Stopping Frappe services..."
        docker compose down -v 2>/dev/null || true
        log_info "✓ Frappe services stopped and removed"
    else
        log_warn "No docker-compose.yml found"
    fi
else
    log_warn "Frappe Docker directory not found at $FRAPPE_DOCKER_DIR"
fi

# Stop all running containers
if docker ps -q | grep -q .; then
    log_info "Stopping all running Docker containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    log_info "✓ All containers stopped"
fi

# Remove all containers
if docker ps -aq | grep -q .; then
    log_info "Removing all Docker containers..."
    docker rm -f $(docker ps -aq) 2>/dev/null || true
    log_info "✓ All containers removed"
else
    log_info "No containers to remove"
fi

################################################################################
# Step 2: Remove networks
################################################################################

log_step "2/5 Removing Docker networks..."

# List custom networks (exclude default ones)
NETWORKS=$(docker network ls --filter "type=custom" -q 2>/dev/null || true)

if [ -n "$NETWORKS" ]; then
    log_info "Removing custom networks..."
    docker network rm $NETWORKS 2>/dev/null || true
    log_info "✓ Networks removed"
else
    log_info "No custom networks to remove"
fi

################################################################################
# Step 3: Remove volumes
################################################################################

log_step "3/5 Removing Docker volumes..."

if docker volume ls -q | grep -q .; then
    log_info "Removing all Docker volumes..."
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    log_info "✓ Volumes removed"
else
    log_info "No volumes to remove"
fi

################################################################################
# Step 4: Remove site data (optional)
################################################################################

if [ "$REMOVE_DATA" = true ]; then
    log_step "4/5 Removing site data..."
    
    if [ "$FORCE" = false ]; then
        log_error "⚠️  WARNING: This will DELETE ALL SITE DATA!"
        echo "This includes:"
        echo "  • All databases"
        echo "  • All uploaded files"
        echo "  • All backups"
        echo "  • Site configurations"
        echo ""
        echo "Type 'DELETE' in capital letters to confirm:"
        read -r confirm
        
        if [ "$confirm" != "DELETE" ]; then
            log_info "Site data removal cancelled"
        else
            if [ -d "$FRAPPE_DOCKER_DIR" ]; then
                log_info "Removing Frappe Docker directory..."
                rm -rf "$FRAPPE_DOCKER_DIR"
                log_info "✓ Site data removed"
            else
                log_warn "Directory not found: $FRAPPE_DOCKER_DIR"
            fi
        fi
    else
        if [ -d "$FRAPPE_DOCKER_DIR" ]; then
            log_info "Removing Frappe Docker directory..."
            rm -rf "$FRAPPE_DOCKER_DIR"
            log_info "✓ Site data removed"
        fi
    fi
else
    log_step "4/5 Skipping site data removal (use --remove-data to delete)"
    if [ -d "$FRAPPE_DOCKER_DIR/sites" ]; then
        log_info "Site data preserved at: $FRAPPE_DOCKER_DIR/sites"
    fi
fi

################################################################################
# Step 5: Remove images (optional)
################################################################################

if [ "$REMOVE_IMAGES" = true ]; then
    log_step "5/5 Removing Docker images..."
    
    if docker images -q | grep -q .; then
        log_info "Removing all Docker images..."
        docker rmi -f $(docker images -aq) 2>/dev/null || true
        log_info "✓ Images removed"
        
        # Prune system
        log_info "Cleaning up Docker system..."
        docker system prune -af --volumes 2>/dev/null || true
        log_info "✓ System cleaned"
    else
        log_info "No images to remove"
    fi
else
    log_step "5/5 Skipping image removal (use --remove-images to delete)"
    
    if docker images | grep -q "custom-frappe"; then
        log_info "Docker images preserved (including custom-frappe)"
    fi
fi

################################################################################
# Step 6: Uninstall Docker (optional)
################################################################################

if [ "$REMOVE_DOCKER" = true ]; then
    echo ""
    log_step "Uninstalling Docker..."
    
    if [ "$FORCE" = false ]; then
        log_error "⚠️  WARNING: This will UNINSTALL DOCKER completely!"
        echo "Type 'UNINSTALL' in capital letters to confirm:"
        read -r confirm
        
        if [ "$confirm" != "UNINSTALL" ]; then
            log_info "Docker uninstallation cancelled"
        else
            uninstall_docker
        fi
    else
        uninstall_docker
    fi
fi

################################################################################
# Uninstall Docker function
################################################################################

uninstall_docker() {
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        log_error "Cannot detect OS"
        return 1
    fi
    
    log_info "Detected OS: $OS"
    
    case $OS in
        ubuntu|debian)
            log_info "Uninstalling Docker on Ubuntu/Debian..."
            
            # Stop Docker service
            systemctl stop docker 2>/dev/null || true
            systemctl disable docker 2>/dev/null || true
            
            # Remove Docker packages
            apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
            
            # Remove Docker repository
            rm -f /etc/apt/sources.list.d/docker.list
            rm -f /etc/apt/keyrings/docker.gpg
            
            log_info "✓ Docker uninstalled"
            ;;
            
        centos|rhel|rocky|alma)
            log_info "Uninstalling Docker on CentOS/RHEL..."
            
            # Stop Docker service
            systemctl stop docker 2>/dev/null || true
            systemctl disable docker 2>/dev/null || true
            
            # Remove Docker packages
            yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
            yum autoremove -y 2>/dev/null || true
            
            # Remove Docker repository
            rm -f /etc/yum.repos.d/docker-ce.repo
            
            log_info "✓ Docker uninstalled"
            ;;
            
        *)
            log_error "Unsupported OS for automatic uninstallation: $OS"
            log_info "Please uninstall Docker manually"
            return 1
            ;;
    esac
    
    # Remove Docker data directories
    log_info "Removing Docker data directories..."
    rm -rf /var/lib/docker 2>/dev/null || true
    rm -rf /var/lib/containerd 2>/dev/null || true
    rm -rf /etc/docker 2>/dev/null || true
    rm -rf /etc/systemd/system/docker.service.d 2>/dev/null || true
    
    log_info "✓ Docker data removed"
}

################################################################################
# Summary
################################################################################

echo ""
echo "=========================================="
log_info "Cleanup Summary"
echo "=========================================="
echo ""
echo "Completed actions:"
echo "  ✓ Stopped and removed all containers"
echo "  ✓ Removed Docker networks"
echo "  ✓ Removed Docker volumes"

if [ "$REMOVE_DATA" = true ]; then
    echo "  ✓ Removed site data"
else
    echo "  - Site data preserved"
fi

if [ "$REMOVE_IMAGES" = true ]; then
    echo "  ✓ Removed Docker images"
else
    echo "  - Docker images preserved"
fi

if [ "$REMOVE_DOCKER" = true ]; then
    echo "  ✓ Uninstalled Docker"
fi

echo ""

# Check remaining disk space
if command -v df &> /dev/null; then
    log_info "Disk space after cleanup:"
    df -h / | tail -1 | awk '{print "  Free: " $4 " (" $5 " used)"}'
fi

echo ""
echo "=========================================="
log_info "Cleanup completed successfully!"
echo "=========================================="
echo ""

if [ "$REMOVE_DATA" = false ]; then
    echo "Note: Site data is still preserved at:"
    echo "  $FRAPPE_DOCKER_DIR"
    echo ""
    echo "To remove site data:"
    echo "  bash cleanup.sh --remove-data"
    echo ""
fi

if [ "$REMOVE_DOCKER" = false ]; then
    echo "Docker is still installed on this system."
    echo "To completely remove Docker:"
    echo "  bash cleanup.sh --remove-docker"
    echo ""
fi

log_info "You can now redeploy with: bash scripts/deploy-production.sh"
