# Frappe/ERPNext Production Docker Setup

This is a complete, production-ready Docker setup for Frappe/ERPNext that you can reuse anywhere. It's based on the official [frappe_docker](https://github.com/frappe/frappe_docker) repository with a simplified, step-by-step workflow.

## 🎯 What This Setup Includes

- **Official frappe_docker repository** - Best practices from Frappe team
- **Custom apps support** - Easy configuration via `apps.json`
- **Environment-based configuration** - All settings in `.env` file
- **Automated scripts** - One-command installation and deployment
- **Production-ready** - Includes SSL, backups, and monitoring setup
- **Reusable** - Copy this folder anywhere and deploy

## 📋 Prerequisites

Before starting, ensure you have:

- **Ubuntu/Debian Linux** (20.04 or later recommended)
- **Minimum 4GB RAM** (8GB+ recommended for production)
- **Minimum 40GB disk space**
- **Root or sudo access**
- **Domain name** (for production with SSL)

## 🚀 Quick Start (Production Deployment)

### Step 1: Clone This Repository

```bash
# Clone to your server
git clone <your-repo-url> frappe-production-setup
cd frappe-production-setup
```

### Step 2: Install Docker & Dependencies

```bash
# Run the installation script (installs Docker, Docker Compose, Git)
chmod +x scripts/install-prerequisites.sh
./scripts/install-prerequisites.sh
```

### Step 3: Configure Your Setup

```bash
# Copy and edit environment variables
cp .env.example .env
nano .env
```

**Important variables to change:**
- `FRAPPE_VERSION` - Set to desired version (e.g., version-15)
- `ERPNEXT_VERSION` - Set to desired version (e.g., v15.93.0)
- `DB_PASSWORD` - Set a strong database password
- `LETSENCRYPT_EMAIL` - Your email for SSL certificates
- `SITES` - Your domain name (e.g., `erp.yourdomain.com`)

### Step 4: Configure Apps (Optional)

Edit `apps.json` to include custom apps:

```bash
nano apps.json
```

**Example:**
```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  }
]
```

### Step 5: Build Custom Image (If using custom apps)

```bash
# Build your custom Frappe image with your apps
chmod +x scripts/build-image.sh
./scripts/build-image.sh
```

This will:
- Read your `apps.json`
- Build a custom Docker image with all specified apps
- Tag it as `custom-frappe:latest`

### Step 6: Deploy Production Setup

```bash
# Deploy with SSL and all production services
chmod +x scripts/deploy-production.sh
./scripts/deploy-production.sh
```

This will:
- Generate the final `docker-compose.yml`
- Start all services (MariaDB, Redis, Frappe, Nginx, etc.)
- Configure SSL with Let's Encrypt
- Create your first site

### Step 7: Create Your Site

After deployment, create your Frappe/ERPNext site:

```bash
# Create a new site
chmod +x scripts/create-site.sh
./scripts/create-site.sh
```

Follow the prompts to enter:
- Site name (your domain)
- Admin password
- Database name (optional)

## 📁 Repository Structure

```
frappe-production-setup/
├── README.md                           # This file
├── .env.example                        # Environment variables template
├── apps.json                          # Custom apps configuration
├── docker-compose.yml                 # Generated compose file (created by scripts)
├── configs/                           # Configuration files
│   ├── .env.production               # Production environment template
│   ├── .env.development              # Development environment template
│   └── nginx-custom.conf             # Custom Nginx configuration (optional)
├── scripts/                           # Automation scripts
│   ├── install-prerequisites.sh      # Install Docker, Docker Compose, Git
│   ├── build-image.sh                # Build custom Frappe image with apps
│   ├── deploy-production.sh          # Deploy production setup with SSL
│   ├── deploy-development.sh         # Deploy development setup
│   ├── create-site.sh                # Create new Frappe site (interactive app selection)
│   ├── drop-site.sh                  # Safely drop/delete a site with backup
│   ├── add-app.sh                    # Add new app to running production
│   ├── uninstall-app.sh              # Uninstall app from site with migration
│   ├── fix-https.sh                  # Diagnose and fix HTTPS/SSL issues
│   ├── backup.sh                     # Backup all sites
│   ├── restore.sh                    # Restore from backup
│   ├── update.sh                     # Update Frappe/ERPNext
│   ├── start.sh                      # Start all containers
│   ├── stop.sh                       # Stop all containers
│   ├── logs.sh                       # View container logs
│   └── cleanup.sh                    # Remove Docker setup completely
└── backups/                           # Backup storage directory
```

## 🔧 Common Operations

### View Logs

```bash
./scripts/logs.sh
```

### Stop Services

```bash
./scripts/stop.sh
```

### Start Services

```bash
./scripts/start.sh
```

### Backup All Sites

```bash
./scripts/backup.sh
```

### Restore from Backup

```bash
./scripts/restore.sh
```

### Add New App to Production

```bash
# Add a new app to running production (rebuilds image and installs)
./scripts/add-app.sh
```

### Delete a Site

```bash
# Safely drop a site with optional backup
./scripts/drop-site.sh
```

### Uninstall App from Site

```bash
# Uninstall an app from a site (with backup and migration)
./scripts/uninstall-app.sh
```

### Fix HTTPS/SSL Issues

```bash
# Diagnose and fix HTTPS/SSL configuration
./scripts/fix-https.sh
```

### Complete Cleanup

```bash
# Remove entire Docker setup (with confirmations)
./scripts/cleanup.sh
```

### Update Frappe/ERPNext

```bash
./scripts/update.sh
```

## 🌐 Development Setup

For local development without SSL:

```bash
# Use development configuration
cp configs/.env.development .env

# Deploy without SSL
chmod +x scripts/deploy-development.sh
./scripts/deploy-development.sh
```

Access at: `http://localhost:8080`

## 🔒 Production Recommendations

1. **Security:**
   - Use strong passwords for `DB_PASSWORD`
   - Enable firewall: `ufw allow 80,443/tcp`
   - Keep system updated: `apt update && apt upgrade`

2. **Backups:**
   - Set up automated backups with cron
   - Store backups off-server
   - Test restore procedure regularly

3. **Monitoring:**
   - Monitor disk space usage
   - Monitor container health
   - Set up log rotation

4. **Performance:**
   - Use SSD storage for database
   - Allocate adequate RAM
   - Monitor resource usage

## 📖 Environment Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `FRAPPE_VERSION` | Frappe framework branch | version-15 | Yes |
| `ERPNEXT_VERSION` | ERPNext version tag | v15.93.0 | Yes |
| `DB_PASSWORD` | MariaDB root password | - | Yes |
| `LETSENCRYPT_EMAIL` | Email for SSL certs | - | Production only |
| `SITES` | Domain names for SSL | - | Production only |
| `HTTP_PUBLISH_PORT` | Port to publish | 8080 | No |
| `CUSTOM_IMAGE` | Custom image name | frappe/erpnext | No |
| `CUSTOM_TAG` | Custom image tag | $ERPNEXT_VERSION | No |

See `.env.example` for complete list.

## 🐛 Troubleshooting

### Containers not starting?

```bash
# Check container status
docker ps -a

# Check logs
./scripts/logs.sh

# Restart services
./scripts/stop.sh
./scripts/start.sh
```

### Site not accessible?

1. Check if containers are running: `docker ps`
2. Check site creation logs: `docker logs frappe-production-setup-create-site-1`
3. Verify domain DNS points to your server
4. Check firewall allows ports 80 and 443

### Database connection errors?

1. Verify `DB_PASSWORD` in `.env`
2. Check MariaDB container: `docker logs frappe-production-setup-db-1`
3. Ensure database is healthy: `docker ps` (should show "healthy" status)

## 📚 Additional Resources

- [Official Frappe Docker Docs](https://github.com/frappe/frappe_docker)
- [Frappe Framework Docs](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com/)

## 🤝 Contributing

This is a template repository. Feel free to:
- Fork and customize for your needs
- Submit improvements
- Share with others

## 📄 License

MIT License - Use freely for personal and commercial projects.

---

**Need help?** Check the [troubleshooting](#-troubleshooting) section or refer to the [official documentation](https://github.com/frappe/frappe_docker).

---

## 🗑️ Complete Cleanup & Removal

### When to Use Cleanup

Use the cleanup script when you need to:
- Start fresh with a new deployment
- Remove a failed installation
- Free up disk space
- Completely remove Docker from server
- Migrate to a different setup

### Cleanup Options

**Option 1: Remove deployment (keep site data)**
```bash
bash scripts/cleanup.sh
```
This removes:
- All Docker containers
- Docker networks
- Docker volumes
- But **preserves** site data for backup/migration

**Option 2: Remove deployment and site data**
```bash
bash scripts/cleanup.sh --remove-data
```
⚠️ **WARNING:** This deletes all site data including databases and files!

**Option 3: Remove Docker images too**
```bash
bash scripts/cleanup.sh --remove-data --remove-images
```
Removes everything including built Docker images.

**Option 4: Nuclear option (remove Docker itself)**
```bash
bash scripts/cleanup.sh --remove-data --remove-images --remove-docker
```
⚠️ **DANGER:** This uninstalls Docker completely from the server!

**Option 5: Force mode (skip confirmations)**
```bash
bash scripts/cleanup.sh --remove-data --remove-images --force
```
⚠️ Use with extreme caution! No confirmation prompts.

### Safety Features

The cleanup script includes multiple safety features:

1. **Confirmations Required**
   - Asks "yes" before starting cleanup
   - Requires typing "DELETE" to remove site data
   - Requires typing "UNINSTALL" to remove Docker

2. **Preserved by Default**
   - Site data is NOT deleted unless `--remove-data` is used
   - Docker images are NOT deleted unless `--remove-images` is used
   - Docker itself is NOT removed unless `--remove-docker` is used

3. **Summary Report**
   - Shows what was cleaned up
   - Shows what was preserved
   - Displays freed disk space

### Typical Cleanup Scenarios

**Scenario 1: Redeploy on same server**
```bash
# Keep site data for migration
bash scripts/cleanup.sh

# Redeploy
bash scripts/deploy-production.sh

# Restore sites
bash scripts/restore.sh site1.com /path/to/backup.sql.gz
```

**Scenario 2: Complete fresh start**
```bash
# Remove everything (asks for confirmation)
bash scripts/cleanup.sh --remove-data --remove-images

# Install and redeploy
bash scripts/deploy-production.sh
bash scripts/create-site.sh newsite.com
```

**Scenario 3: Remove Docker completely**
```bash
# Complete removal including Docker
bash scripts/cleanup.sh --remove-data --remove-images --remove-docker

# Server is now clean, Docker is uninstalled
```

**Scenario 4: Free up space but keep deployment**
```bash
# Just clean up unused Docker resources
docker system prune -af --volumes

# Or use cleanup to remove old containers
bash scripts/cleanup.sh
bash scripts/start.sh
```

### What Gets Removed

| Component | Default | --remove-data | --remove-images | --remove-docker |
|-----------|---------|---------------|-----------------|-----------------|
| Containers | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Networks | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Volumes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Site Data | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Docker Images | ❌ No | ❌ No | ✅ Yes | ✅ Yes |
| Docker Engine | ❌ No | ❌ No | ❌ No | ✅ Yes |

### Post-Cleanup Steps

After cleanup, depending on what was removed:

**If site data was preserved:**
```bash
# Site data is still in /home/frappe/frappe_docker/sites/
# You can redeploy and restore
bash scripts/deploy-production.sh
bash scripts/restore.sh site1.com /path/to/backup.sql.gz
```

**If everything was removed:**
```bash
# Start from scratch
bash scripts/build-image.sh
bash scripts/deploy-production.sh
bash scripts/create-site.sh site1.yourdomain.com
```

**If Docker was uninstalled:**
```bash
# Reinstall Docker first
sudo bash scripts/install-prerequisites.sh
# Logout and login
# Then deploy
bash scripts/build-image.sh
bash scripts/deploy-production.sh
```

