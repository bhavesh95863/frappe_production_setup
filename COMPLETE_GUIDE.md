# Complete Frappe/ERPNext Docker Deployment Guide

## 📖 Quick Navigation

This repository contains everything you need to deploy Frappe/ERPNext in production. Choose your path:

### 🚀 For Quick Deployment (Recommended)

**Start Here:** [README.md](README.md)

1. **Install Prerequisites**
   ```bash
   sudo bash scripts/install-prerequisites.sh
   ```

2. **Configure**
   ```bash
   cp configs/example.env configs/.env
   cp configs/example-apps.json configs/apps.json
   # Edit both files with your settings
   ```

3. **Build & Deploy**
   ```bash
   bash scripts/build-image.sh
   bash scripts/deploy-production.sh
   ```

4. **Create Site**
   ```bash
   bash scripts/create-site.sh yourdomain.com
   ```

---

### 📚 For Detailed Understanding

If you want to understand every step, read these in order:

1. **[README.md](README.md)** - Overview, features, and architecture
2. **[/home/frappe/DEPLOYMENT_GUIDE.md](/home/frappe/DEPLOYMENT_GUIDE.md)** - Detailed step-by-step guide with explanations
3. **[EXAMPLES.md](EXAMPLES.md)** - Real-world configuration examples
4. **[MIGRATION.md](MIGRATION.md)** - If migrating from traditional bench

---

## 🗂️ Repository Structure

```
frappe-production-setup/
├── README.md                     # Main documentation (START HERE)
├── QUICKSTART.md                 # 5-minute quick start
├── COMPLETE_GUIDE.md            # This file - navigation guide
├── EXAMPLES.md                   # Configuration examples
├── MIGRATION.md                  # Bench to Docker migration
├── INDEX.md                      # Documentation index
│
├── configs/                      # Configuration files
│   ├── example.env              # Example environment variables
│   ├── example-apps.json        # Example apps configuration
│   ├── .env.production          # Production template
│   └── .env.development         # Development template
│
└── scripts/                      # Automation scripts
    ├── install-prerequisites.sh  # Install Docker & dependencies
    ├── build-image.sh           # Build custom Docker image
    ├── deploy-production.sh     # Deploy production environment
    ├── deploy-development.sh    # Deploy development environment
    ├── create-site.sh           # Create new site
    ├── backup.sh                # Backup sites
    ├── restore.sh               # Restore from backup
    ├── update.sh                # Update apps
    ├── start.sh                 # Start services
    ├── stop.sh                  # Stop services
    └── logs.sh                  # View logs
```

---

## 🎯 Common Use Cases

### First Time Setup
```bash
# 1. Install Docker
sudo bash scripts/install-prerequisites.sh

# 2. Configure
cp configs/example.env configs/.env
nano configs/.env  # Edit your domains, passwords

# 3. Configure apps
cp configs/example-apps.json configs/apps.json
nano configs/apps.json  # Add your custom apps

# 4. Build and deploy
bash scripts/build-image.sh
bash scripts/deploy-production.sh

# 5. Create first site
bash scripts/create-site.sh site1.yourdomain.com
```

### Adding a New Site
```bash
bash scripts/create-site.sh newsite.yourdomain.com
```

### Daily Operations
```bash
# View logs
bash scripts/logs.sh backend -f

# Backup all sites
bash scripts/backup.sh --all --with-files

# Update apps
bash scripts/update.sh

# Restart services
bash scripts/stop.sh && bash scripts/start.sh
```

### Deploying on New Server
```bash
# 1. Clone this repo
git clone <your-repo-url> frappe-production-setup
cd frappe-production-setup

# 2. Run prerequisites
sudo bash scripts/install-prerequisites.sh

# 3. Copy your existing .env and apps.json to configs/
cp /path/to/your/.env configs/
cp /path/to/your/apps.json configs/

# 4. Deploy
bash scripts/build-image.sh
bash scripts/deploy-production.sh

# 5. Create sites
bash scripts/create-site.sh site1.yourdomain.com
bash scripts/create-site.sh site2.yourdomain.com
```

---

## 📝 Configuration Files Explained

### configs/.env
Main configuration file with all environment variables:
- **SITES** - Your domain names (requires DNS setup)
- **LETSENCRYPT_EMAIL** - Email for SSL certificates
- **DB_PASSWORD** - Database password
- **CUSTOM_IMAGE** - Your custom image name

See [configs/example.env](configs/example.env) for all options.

### configs/apps.json
Defines which Frappe apps to install in your custom image:
```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  }
]
```

See [configs/example-apps.json](configs/example-apps.json) for examples.

---

## 🛠️ All Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [install-prerequisites.sh](scripts/install-prerequisites.sh) | Install Docker & dependencies | `sudo bash scripts/install-prerequisites.sh` |
| [build-image.sh](scripts/build-image.sh) | Build custom Docker image | `bash scripts/build-image.sh [--rebuild] [--no-cache]` |
| [deploy-production.sh](scripts/deploy-production.sh) | Deploy production environment | `bash scripts/deploy-production.sh` |
| [deploy-development.sh](scripts/deploy-development.sh) | Deploy development environment | `bash scripts/deploy-development.sh` |
| [create-site.sh](scripts/create-site.sh) | Create new site | `bash scripts/create-site.sh DOMAIN [OPTIONS]` |
| [backup.sh](scripts/backup.sh) | Backup sites | `bash scripts/backup.sh [SITE] [--with-files] [--all]` |
| [restore.sh](scripts/restore.sh) | Restore from backup | `bash scripts/restore.sh SITE BACKUP [FILES]` |
| [update.sh](scripts/update.sh) | Update apps | `bash scripts/update.sh [SITE]` |
| [start.sh](scripts/start.sh) | Start all services | `bash scripts/start.sh` |
| [stop.sh](scripts/stop.sh) | Stop all services | `bash scripts/stop.sh` |
| [logs.sh](scripts/logs.sh) | View logs | `bash scripts/logs.sh [SERVICE] [-f]` |

---

## 🔍 Troubleshooting Quick Reference

### Services won't start
```bash
bash scripts/logs.sh
docker compose ps
docker compose restart
```

### SSL not working
```bash
# Check DNS
nslookup yoursite.com 8.8.8.8

# Check configuration
grep SITES /home/frappe/frappe_docker/.env

# Restart proxy
docker compose restart proxy
```

### Site not accessible
```bash
# Check site exists
docker compose exec backend ls sites/

# Check site health
docker compose exec backend bench --site yoursite.com doctor

# Clear cache
docker compose exec backend bench --site yoursite.com clear-cache
```

### Build failures
```bash
# Clean and rebuild
docker builder prune -a
bash scripts/build-image.sh --rebuild --no-cache
```

For detailed troubleshooting, see [README.md](README.md) and [/home/frappe/DEPLOYMENT_GUIDE.md](/home/frappe/DEPLOYMENT_GUIDE.md).

---

## 📞 Need Help?

1. **Check Documentation**
   - [README.md](README.md) - Main guide
   - [DEPLOYMENT_GUIDE.md](/home/frappe/DEPLOYMENT_GUIDE.md) - Detailed steps
   - [EXAMPLES.md](EXAMPLES.md) - Working examples

2. **Community Support**
   - [Frappe Forum](https://discuss.frappe.io)
   - [frappe_docker Issues](https://github.com/frappe/frappe_docker/issues)

3. **Documentation**
   - [Frappe Framework](https://frappeframework.com/docs)
   - [ERPNext](https://docs.erpnext.com)

---

## ✅ Pre-Flight Checklist

Before deploying, ensure:

- [ ] Server meets minimum requirements (4GB RAM, 40GB disk)
- [ ] Docker and Docker Compose installed
- [ ] DNS A records configured for all domains
- [ ] configs/.env file configured with your settings
- [ ] configs/apps.json configured with your apps
- [ ] Strong passwords set in .env
- [ ] LETSENCRYPT_EMAIL is valid
- [ ] Firewall allows ports 80, 443

---

## 🎓 Learning Path

**Beginner** → Start with [QUICKSTART.md](QUICKSTART.md)

**Intermediate** → Read [README.md](README.md) and use scripts

**Advanced** → Study [DEPLOYMENT_GUIDE.md](/home/frappe/DEPLOYMENT_GUIDE.md) and [EXAMPLES.md](EXAMPLES.md)

**Expert** → Customize scripts and read frappe_docker source

---

**Made with ❤️ for Frappe/ERPNext community**

**Repository:** frappe-production-setup  
**Based on:** [frappe/frappe_docker](https://github.com/frappe/frappe_docker)  
**Version:** 1.0 (December 2025)
