# 🚀 GLPI Interactive Installation Script for Debian 12.9

[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Debian](https://img.shields.io/badge/Debian-12.9-red.svg)](https://www.debian.org/)
[![GLPI](https://img.shields.io/badge/GLPI-10.0.x-blue.svg)](https://glpi-project.org/)
[![Bash](https://img.shields.io/badge/Bash-5.2+-green.svg)](https://www.gnu.org/software/bash/)

An interactive, semi-automated installation script for **GLPI (IT Asset Management)** on **Debian 12.9 (Bookworm)**. This script sets up the complete server environment (Apache, PHP, MariaDB) and configures daily backups, while allowing you to complete the GLPI web installation manually.

## ✨ Features

- ✅ **Fully Interactive** - Prompts for all configuration options
- ✅ **Debian 12.9 Optimized** - Uses native packages from Debian repositories
- ✅ **PHP 8.2 Support** - Configured with optimal settings for GLPI
- ✅ **MariaDB Database** - Automatic database and user creation
- ✅ **Flexible Password Options** - Choose your own or generate secure random passwords
- ✅ **Apache Virtual Host** - Automatically configured with optional HTTPS (Let's Encrypt)
- ✅ **Daily Automated Backups** - Configurable backup schedule with retention policy
- ✅ **Email Notifications** - Backup status alerts to your email
- ✅ **Interactive Summary** - Review all settings before installation
- ✅ **Comprehensive Logging** - All actions logged for troubleshooting
- ✅ **Security Focused** - Best practices applied by default

## 📋 Prerequisites

- **Debian 12.9 (Bookworm)** - Fresh installation recommended
- **Root access** - Script must be run as root or with sudo
- **Internet connection** - For downloading packages and GLPI
- **Minimum 2GB RAM** - 4GB recommended for production
- **Minimum 10GB free disk space** - More depending on asset data

## 🚀 Quick Installation

### 1. Download the Script

```bash
wget https://raw.githubusercontent.com/voogarix/glpi-interactive-installer/main/glpi.sh
# or
curl -O https://raw.githubusercontent.com/voogarix/glpi-interactive-installer/main/glpi.sh
```
### 2. Make it Executable
```bash
chmod +x glpi.sh
```
### 3. Run as Root
```bash
sudo ./glpi.sh
```
### 4. Follow the Interactive Prompts
The script will guide you through:

Database configuration (name, user, password)

Web server settings (domain/IP, HTTPS)

Email configuration (for backup alerts)

Backup settings (directory, retention, schedule)

### 5. Complete GLPI Web Installation
After the script finishes:

Open your browser to http://your-domain-or-ip

Follow the GLPI web installation wizard

Enter the database credentials provided by the script

Complete the setup and remove the install directory

## 📝 Interactive Configuration Options
```text
Database Configuration
Option	Description	Default
Database Name	Name for GLPI database	glpidb
Database User	Database user for GLPI	glpiuser
Password Option	Choose your password or auto-generate	Auto-generate
Web Server Configuration
Option	Description	Default
Domain/IP	Your GLPI access URL/IP	Required
HTTPS	Enable Let's Encrypt SSL	n (No)
Email Configuration
Option	Description	Default
Admin Email	For backup notifications	Required
Backup Configuration
Option	Description	Default
Backup Directory	Where to store backups	/var/backups/glpi
Retention Days	How long to keep backups	30
Backup Time	When to run daily backup (24h)	02:00
```
### 📂 Installation Structure
```text
/var/www/html/glpi/           # GLPI installation directory
├── public/                   # Web root
├── config/                   # Configuration files
├── files/                    # Uploads and generated files
└── install/                  # Installer (remove after setup)

/var/log/
├── glpi/                     # GLPI logs
└── apache2/                  # Apache logs

/var/backups/glpi/            # Backup directory
├── glpi_backup_*.tar.gz      # Daily backups
└── backup.log               # Backup logs

/root/glpi_installation_info.txt  # Installation summary
/var/log/glpi_install_*.log       # Installation log
```
## 🔧 Post-Installation Tasks

### 1. Complete GLPI Web Installation

```bash
# Access your GLPI instance
http://your-server-ip-or-domain

# Use the database credentials from the installation summary
# Database host: localhost
# Database name: [your-db-name]
# Database user: [your-db-user]
# Database password: [your-db-password]
```
### 2. Secure Your Installation

```bash
# Remove the install directory after setup
sudo rm -rf /var/www/html/glpi/install

# Change default GLPI admin password
# Login with glpi/glpi and change immediately

# Set proper file permissions
sudo chmod 640 /var/www/html/glpi/config/config_db.php
```
### 3. Test Backup System
```bash
# Run manual backup test
sudo /usr/local/bin/glpi_backup.sh

# Check backup log
sudo tail -f /var/backups/glpi/backup.log
```

## 🛠️ Maintenance Commands

### Service management

```bash
# Restart Apache
sudo systemctl restart apache2

# Restart MariaDB
sudo systemctl restart mariadb

# Check service status
sudo systemctl status apache2 mariadb
```

## Backup Management

```bash
# Manual backup
sudo /usr/local/bin/glpi_backup.sh

# List backups
ls -lh /var/backups/glpi/

# Restore from backup
sudo tar -xzf /var/backups/glpi/glpi_backup_*.tar.gz -C /
```

## Log Monitoring

```bash
# Watch GLPI logs
sudo tail -f /var/log/glpi/*.log

# Watch Apache logs
sudo tail -f /var/log/apache2/glpi_error.log

# Watch backup logs
sudo tail -f /var/backups/glpi/backup.log
```
