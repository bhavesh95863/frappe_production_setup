# Usage Examples - Real-World Scenarios

This document shows real-world examples of using this setup in different scenarios.

## 📝 Example 1: Fresh Production Deployment

**Scenario:** You have a new Ubuntu server and want to deploy ERPNext for your company.

**Steps:**

```bash
# 1. SSH to your server
ssh root@your-server-ip

# 2. Clone this repository
cd /home
git clone https://github.com/yourusername/frappe-production-setup.git
cd frappe-production-setup

# 3. Install Docker and prerequisites
./scripts/install-prerequisites.sh

# 4. Log out and back in (for Docker group)
exit
# SSH back in
ssh root@your-server-ip

# 5. Configure environment
cd /home/frappe-production-setup
cp .env.example .env
nano .env

# Edit these values:
# DB_PASSWORD=MySecurePass123!@#
# LETSENCRYPT_EMAIL=admin@mycompany.com
# SITES=`erp.mycompany.com`

# 6. Keep default apps.json or customize
cat apps.json  # Review default apps

# 7. Build custom image (optional, if you modified apps.json)
./scripts/build-image.sh

# If you built custom image, update .env:
# CUSTOM_IMAGE=custom-frappe
# CUSTOM_TAG=latest

# 8. Deploy production
./scripts/deploy-production.sh

# 9. Wait for services (check status)
docker compose ps
# Wait until all show "healthy" or "running"

# 10. Create your site
./scripts/create-site.sh
# Enter: erp.mycompany.com
# Enter: strong admin password
# Install ERPNext: Yes

# 11. Access your site
# Open browser: https://erp.mycompany.com
# Login: Administrator / [your password]
```

**Time:** ~30 minutes (including image build)

---

## 📝 Example 2: Local Development Setup

**Scenario:** Developer wants to test ERPNext locally before deploying.

**Steps:**

```bash
# 1. On your local machine (Linux/Mac with Docker)
git clone https://github.com/yourusername/frappe-production-setup.git
cd frappe-production-setup

# 2. Configure for development
cp configs/.env.development .env

# Edit database password only
nano .env
# DB_PASSWORD=admin123
# HTTP_PUBLISH_PORT=8080

# 3. Deploy development setup
./scripts/deploy-development.sh

# 4. Create site
./scripts/create-site.sh
# Enter: site1.localhost
# Enter admin password
# Install ERPNext: Yes

# 5. Access
# Open: http://localhost:8080
# Login: Administrator / [your password]

# 6. When done, stop services
./scripts/stop.sh
```

**Time:** ~15 minutes

---

## 📝 Example 3: Custom Apps Installation

**Scenario:** You want ERPNext + HRMS + Custom App

**Steps:**

```bash
# 1. Setup as in Example 1, but customize apps.json before building

cd /home/frappe-production-setup
cp .env.example .env
nano .env  # Configure as needed

# 2. Customize apps.json
nano apps.json

# Add your custom app:
# [
#   {
#     "url": "https://github.com/frappe/erpnext",
#     "branch": "version-15"
#   },
#   {
#     "url": "https://github.com/frappe/hrms",
#     "branch": "version-15"
#   },
#   {
#     "url": "https://github.com/yourusername/custom_app",
#     "branch": "main"
#   }
# ]

# 3. Build custom image
./scripts/build-image.sh

# 4. Update .env to use custom image
nano .env
# Add:
# CUSTOM_IMAGE=custom-frappe
# CUSTOM_TAG=latest

# 5. Deploy
./scripts/deploy-production.sh

# 6. Create site with custom app
./scripts/create-site.sh
# After creating site, install custom app:
docker compose exec backend bench --site your-site.com install-app custom_app
```

**Time:** ~45 minutes

---

## 📝 Example 4: Multi-Site Setup

**Scenario:** Host multiple ERPNext sites on one server

**Steps:**

```bash
# 1. Deploy once (as in Example 1)
# Complete steps 1-9 from Example 1

# 2. Create first site
./scripts/create-site.sh
# Enter: client1.example.com
# Install ERPNext

# 3. Create second site
./scripts/create-site.sh
# Enter: client2.example.com
# Install ERPNext

# 4. Create third site
./scripts/create-site.sh
# Enter: client3.example.com
# Install ERPNext

# 5. Update .env with all sites
nano .env
# SITES=`client1.example.com`,`client2.example.com`,`client3.example.com`

# 6. Restart services to apply changes
./scripts/stop.sh
./scripts/start.sh

# 7. Each site accessible at its domain
# https://client1.example.com
# https://client2.example.com
# https://client3.example.com
```

**Note:** Make sure all domains point to your server IP.

---

## 📝 Example 5: Backup and Restore

**Scenario:** Regular backups and disaster recovery

**Steps:**

### Regular Backup

```bash
# 1. Manual backup
cd /home/frappe-production-setup
./scripts/backup.sh

# Backups saved to: ./backups/

# 2. Automated daily backups with cron
crontab -e
# Add this line:
# 0 2 * * * cd /home/frappe-production-setup && ./scripts/backup.sh

# 3. Copy backups off-server (recommended)
# On your local machine:
scp -r root@your-server:/home/frappe-production-setup/backups/ ./local-backups/

# Or use rsync for incremental:
rsync -avz root@your-server:/home/frappe-production-setup/backups/ ./local-backups/
```

### Restore

```bash
# 1. If backups are on new server, upload them
scp -r ./local-backups/* root@new-server:/home/frappe-production-setup/backups/

# 2. On server, restore
cd /home/frappe-production-setup
./scripts/restore.sh
# Select the backup to restore

# 3. Verify
docker compose exec backend bench --site your-site.com migrate
```

---

## 📝 Example 6: Update to Latest Version

**Scenario:** Update ERPNext from v15.93.0 to v15.100.0

**Steps:**

```bash
# 1. BACKUP FIRST!
cd /home/frappe-production-setup
./scripts/backup.sh

# 2. Update version in .env
nano .env
# Change: ERPNEXT_VERSION=v15.100.0

# 3. If using custom image, rebuild
./scripts/build-image.sh

# 4. Run update
./scripts/update.sh

# This will:
# - Pull new images
# - Restart containers
# - Migrate all sites
# - Rebuild assets

# 5. Verify
# Access your site and check version
# Help > About
```

**Time:** ~20 minutes + migration time

---

## 📝 Example 7: Migrating from Existing Installation

**Scenario:** You have bench-based installation, want to move to Docker

**Steps:**

```bash
# ON OLD SERVER:
# 1. Backup current installation
cd ~/frappe-bench
bench --site mysite.com backup --with-files

# 2. Download backups
cd ~/frappe-bench/sites/mysite.com/private/backups/
# Copy these files to your local machine:
# - *-database.sql.gz
# - *-files.tar
# - *-private-files.tar

# ON NEW SERVER:
# 3. Setup new server (Example 1, steps 1-9)
cd /home/frappe-production-setup
# Complete configuration and deployment

# 4. Upload backup files
# From local machine:
scp *-database.sql.gz root@new-server:/home/frappe-production-setup/backups/
scp *-files.tar root@new-server:/home/frappe-production-setup/backups/
scp *-private-files.tar root@new-server:/home/frappe-production-setup/backups/

# 5. Create site (same name as old site)
./scripts/create-site.sh
# Enter: mysite.com
# Don't install ERPNext yet

# 6. Organize backups
mkdir -p backups/mysite.com_restore
mv backups/*-database.sql.gz backups/mysite.com_restore/
mv backups/*-files.tar backups/mysite.com_restore/
mv backups/*-private-files.tar backups/mysite.com_restore/

# 7. Restore
./scripts/restore.sh
# Select the backup

# 8. Update DNS to point to new server

# 9. Keep old server running for 1 week as backup
```

See [MIGRATION.md](MIGRATION.md) for detailed migration guide.

---

## 📝 Example 8: Monitoring and Maintenance

**Scenario:** Daily operations and monitoring

**Common Commands:**

```bash
cd /home/frappe-production-setup

# Check services health
docker compose ps

# View real-time logs
./scripts/logs.sh

# View specific service logs
./scripts/logs.sh backend
./scripts/logs.sh frontend
./scripts/logs.sh db

# Check disk space
df -h

# Check container resource usage
docker stats

# Access backend shell
docker compose exec backend bash

# Run bench commands
docker compose exec backend bench --help
docker compose exec backend bench --site mysite.com console
docker compose exec backend bench --site mysite.com mariadb

# Restart specific service
docker compose restart backend
docker compose restart frontend

# Full restart
./scripts/stop.sh
./scripts/start.sh

# View all sites
docker compose exec backend ls sites/
```

---

## 📝 Example 9: Adding Users and Permissions

**Scenario:** Set up users for your team

**Steps:**

```bash
# Access your site: https://your-site.com
# Login as Administrator

# Via UI:
# 1. Go to: User > User List
# 2. Click: New
# 3. Fill details:
#    - Email: user@company.com
#    - First Name: John
#    - Last Name: Doe
#    - Role: Accounts Manager (or custom role)
# 4. Save
# 5. Send welcome email

# Via console (bulk users):
docker compose exec backend bench --site your-site.com console

# In Python console:
frappe.get_doc({
    "doctype": "User",
    "email": "user@company.com",
    "first_name": "John",
    "last_name": "Doe",
    "send_welcome_email": 1,
    "roles": [{"role": "Accounts Manager"}]
}).insert()

frappe.db.commit()
exit()
```

---

## 📝 Example 10: SSL Certificate Issues

**Scenario:** SSL certificate not generating or expired

**Steps:**

```bash
# 1. Verify DNS points to your server
nslookup your-domain.com
# Should show your server IP

# 2. Check frontend/traefik logs
cd /home/frappe-production-setup
./scripts/logs.sh frontend

# 3. Verify ports are open
sudo netstat -tulpn | grep -E ':(80|443)'

# 4. Restart to retry SSL
./scripts/stop.sh
./scripts/start.sh

# 5. Manual certificate check
docker compose exec frontend cat /etc/letsencrypt/live/your-domain/fullchain.pem

# 6. If still issues, check .env
cat .env | grep -E '(LETSENCRYPT|SITES)'

# 7. Force certificate renewal (if expired)
docker compose exec frontend certbot renew --force-renewal

# 8. Restart
./scripts/stop.sh
./scripts/start.sh
```

---

## 💡 Tips and Best Practices

### Daily Operations
- Check logs daily: `./scripts/logs.sh | tail -100`
- Monitor disk space: `df -h`
- Review backups: `ls -lh backups/`

### Weekly Tasks
- Run backups: `./scripts/backup.sh`
- Check for updates: `docker compose pull --dry-run`
- Review security logs: `./scripts/logs.sh | grep -i error`

### Monthly Tasks
- Update system: `apt update && apt upgrade`
- Review user access
- Check certificate expiry
- Test restore procedure

### Performance Optimization
```bash
# Check container stats
docker stats

# Adjust worker count if needed
docker compose exec backend bench set-config -g worker_processes 4

# Clear cache
docker compose exec backend bench --site your-site.com clear-cache

# Rebuild search index
docker compose exec backend bench --site your-site.com build-search-index
```

---

## 🆘 Quick Troubleshooting

| Issue | Command | Solution |
|-------|---------|----------|
| Services down | `docker compose ps` | `./scripts/start.sh` |
| High CPU | `docker stats` | Restart: `./scripts/stop.sh && ./scripts/start.sh` |
| Disk full | `df -h` | Clean old backups, Docker images |
| Can't login | Check logs | `./scripts/logs.sh backend` |
| Slow site | Clear cache | `docker compose exec backend bench clear-cache` |
| DB connection error | Check DB | `./scripts/logs.sh db` |

---

**These examples cover 90% of real-world scenarios. For more, see [README.md](README.md) and [Official Docs](https://github.com/frappe/frappe_docker).**
