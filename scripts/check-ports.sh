#!/bin/bash

echo "=========================================="
echo "Port & SSL Diagnostics"
echo "=========================================="
echo ""

cd "$(dirname "$0")/.."

echo "1. Checking what's listening on ports 80 and 443:"
echo ""
sudo ss -tuln | grep -E ':80 |:443 ' || echo "No services listening on 80/443"
echo ""

echo "2. Checking Docker Compose proxy service:"
echo ""
docker compose ps proxy
echo ""

echo "3. Checking if proxy container has port mappings:"
echo ""
docker compose port proxy 80 2>/dev/null || echo "Port 80 not mapped"
docker compose port proxy 443 2>/dev/null || echo "Port 443 not mapped"
echo ""

echo "4. Checking docker-compose.yml for port configuration:"
echo ""
if [ -f "docker-compose.yml" ]; then
    grep -A 5 "proxy:" docker-compose.yml | grep -E "ports:|80|443" || echo "No explicit port mapping found"
else
    echo "docker-compose.yml not found"
fi
echo ""

echo "5. Checking if Traefik is using host network mode:"
echo ""
docker inspect frappe_docker-proxy-1 2>/dev/null | grep -E "NetworkMode|PortBindings" -A 3 || echo "Could not inspect proxy container"
echo ""

echo "6. Testing HTTP access from inside server:"
echo ""
curl -I http://localhost 2>&1 | head -5
echo ""

echo "=========================================="
echo "Suggested fixes:"
echo "=========================================="
echo ""
echo "If port 80 is not listening:"
echo "  1. Ensure docker-compose.yml has proper port mapping"
echo "  2. Restart services: docker compose down && docker compose up -d"
echo "  3. Check for port conflicts: sudo lsof -i :80"
echo ""
echo "If using Traefik (which you are):"
echo "  • Traefik should handle ports 80 and 443"
echo "  • Check: docker compose logs proxy | grep -i bind"
echo ""
