# 🚀 GLPI Interactive Installation Script for Debian 12.9

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
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
wget https://raw.githubusercontent.com/voogarix/glpi-interactive-installer/main/glpi_install.sh
# or
curl -O https://raw.githubusercontent.com/voogarix/glpi-interactive-installer/main/glpi_install.sh
