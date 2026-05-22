#!/bin/bash

# GLPI Semi-Automated Installation Script for Debian
# Supports Debian 11 (Bullseye), 12 (Bookworm), and 13 (Trixie)
# Sets up the server environment, database, and web server
# User completes GLPI installation via web browser

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Log file
LOGFILE="/var/log/glpi_install_$(date +%Y%m%d_%H%M%S).log"

# Default values
DB_NAME="glpidb"
DB_USER=""
DB_PASS=""
DOMAIN_NAME=""
ADMIN_EMAIL=""
BACKUP_DIR="/var/backups/glpi"
BACKUP_RETENTION="30"
BACKUP_TIME="02:00"

# OS detection variables
OS_VERSION=""
OS_CODENAME=""
PHP_VERSION=""
PHP_PACKAGES=""

# Functions
log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

print_color() {
    echo -e "${2}$1${NC}"
}

validate_yes_no() {
    [[ "$1" =~ ^[YyNn]$ ]]
}

validate_domain() {
    [[ "$1" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]
}

validate_email() {
    [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

detect_os() {
    print_color "Detecting operating system..." "$YELLOW"
    
    if [ -f /etc/debian_version ]; then
        OS_VERSION=$(cat /etc/debian_version | cut -d. -f1)
        OS_CODENAME=$(lsb_release -sc 2>/dev/null || echo "")
        
        case $OS_VERSION in
            11)
                OS_CODENAME="bullseye"
                PHP_VERSION="7.4"
                print_color "Detected: Debian 11 (Bullseye) - PHP $PHP_VERSION" "$GREEN"
                ;;
            12)
                OS_CODENAME="bookworm"
                PHP_VERSION="8.2"
                print_color "Detected: Debian 12 (Bookworm) - PHP $PHP_VERSION" "$GREEN"
                ;;
            13)
                OS_CODENAME="trixie"
                PHP_VERSION="8.4"
                print_color "Detected: Debian 13 (Trixie) - PHP $PHP_VERSION" "$GREEN"
                ;;
            *)
                print_color "Detected: Debian $OS_VERSION (Unknown codename)" "$YELLOW"
                print_color "Will attempt generic Debian installation" "$YELLOW"
                PHP_VERSION="8.2"
                ;;
        esac
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" ]]; then
            OS_VERSION=$VERSION_ID
            OS_CODENAME=$VERSION_CODENAME
            print_color "Detected: Debian $OS_VERSION ($OS_CODENAME)" "$GREEN"
            
            case $OS_VERSION in
                11)
                    PHP_VERSION="7.4"
                    ;;
                12)
                    PHP_VERSION="8.2"
                    ;;
                13)
                    PHP_VERSION="8.4"
                    ;;
                *)
                    PHP_VERSION="8.2"
                    ;;
            esac
        else
            print_color "This script is designed for Debian only!" "$RED"
            exit 1
        fi
    else
        print_color "Cannot detect operating system!" "$RED"
        exit 1
    fi
    
    # Configure PHP packages based on OS version
    if [[ $OS_VERSION == "11" ]]; then
        PHP_PACKAGES="php7.4 php7.4-mysql php7.4-curl php7.4-gd php7.4-intel php7.4-ldap php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-zip php7.4-apcu libapache2-mod-php7.4"
    elif [[ $OS_VERSION == "12" ]]; then
        PHP_PACKAGES="php8.2 php8.2-mysql php8.2-curl php8.2-gd php8.2-intl php8.2-ldap php8.2-xml php8.2-mbstring php8.2-bz2 php8.2-zip php8.2-apcu libapache2-mod-php8.2"
    elif [[ $OS_VERSION == "13" ]]; then
        PHP_PACKAGES="php8.4 php8.4-mysql php8.4-curl php8.4-gd php8.4-intl php8.4-ldap php8.4-xml php8.4-mbstring php8.4-bz2 php8.4-zip php8.4-apcu libapache2-mod-php8.4"
    else
        # Generic PHP packages for unknown versions
        PHP_PACKAGES="php php-mysql php-curl php-gd php-intl php-ldap php-xml php-mbstring php-bz2 php-zip php-apcu libapache2-mod-php"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_color "This script must be run as root or with sudo" "$RED"
        exit 1
    fi
}

install_sury_repo() {
    # Only needed for Debian 11 and 12 to get newer PHP versions
    if [[ $OS_VERSION == "11" ]] || [[ $OS_VERSION == "12" ]]; then
        print_color "Adding SURY PHP repository for Debian $OS_VERSION..." "$YELLOW"
        
        apt install -y -qq lsb-release ca-certificates apt-transport-https wget 2>&1 | tee -a "$LOGFILE"
        wget -q https://packages.sury.org/php/apt.gpg -O /etc/apt/trusted.gpg.d/php.gpg
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
        apt update -qq 2>&1 | tee -a "$LOGFILE"
    fi
}

# Check if running as root
check_root

# Detect OS
detect_os

# Welcome message
clear
echo "============================================="
echo "    GLPI Installation Script - Debian        "
echo "============================================="
echo ""
print_color "Detected: Debian $OS_VERSION ($OS_CODENAME)" "$CYAN"
print_color "PHP Version: $PHP_VERSION" "$CYAN"
echo ""
print_color "This script will set up the server environment for GLPI." "$GREEN"
print_color "You will complete the GLPI installation via web browser." "$GREEN"
echo ""

log_message "Starting GLPI server setup on Debian $OS_VERSION ($OS_CODENAME)"
log_message "PHP version: $PHP_VERSION"

# Collect user input
echo "============================================="
echo "           Database Configuration             "
echo "============================================="
echo ""

# Database name
while true; do
    read -p "Enter database name for GLPI [glpidb]: " DB_NAME
    DB_NAME=${DB_NAME:-glpidb}
    if [[ "$DB_NAME" =~ ^[a-zA-Z0-9_]+$ ]]; then
        break
    else
        print_color "Invalid database name. Use only letters, numbers and underscores." "$RED"
    fi
done

# Database user
while true; do
    read -p "Enter database user for GLPI [glpiuser]: " DB_USER
    DB_USER=${DB_USER:-glpiuser}
    if [[ "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
        break
    else
        print_color "Invalid username. Use only letters, numbers and underscores." "$RED"
    fi
done

# Database password option
echo ""
echo "Database password options:"
echo "1) Enter my own password"
echo "2) Generate a secure random password"
read -p "Select option (1-2) [2]: " PASSWORD_OPTION
PASSWORD_OPTION=${PASSWORD_OPTION:-2}

if [[ "$PASSWORD_OPTION" == "1" ]]; then
    while true; do
        read -s -p "Enter database password: " DB_PASS
        echo ""
        if [[ ${#DB_PASS} -ge 8 ]]; then
            read -s -p "Confirm database password: " DB_PASS_CONFIRM
            echo ""
            if [[ "$DB_PASS" == "$DB_PASS_CONFIRM" ]]; then
                break
            else
                print_color "Passwords do not match. Please try again." "$RED"
            fi
        else
            print_color "Password must be at least 8 characters long." "$RED"
        fi
    done
else
    DB_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c16)
    print_color "Generated secure password: $DB_PASS" "$GREEN"
    echo ""
fi

echo ""
echo "============================================="
echo "           Web Server Configuration           "
echo "============================================="
echo ""

# Domain or IP
while true; do
    read -p "Enter domain name or IP address for GLPI access: " DOMAIN_NAME
    if [[ -n "$DOMAIN_NAME" ]]; then
        break
    else
        print_color "Domain or IP cannot be empty." "$RED"
    fi
done

# HTTPS option
read -p "Enable HTTPS with Let's Encrypt? (y/n) [n]: " ENABLE_HTTPS
ENABLE_HTTPS=${ENABLE_HTTPS:-n}

if [[ "$ENABLE_HTTPS" =~ ^[Yy]$ ]]; then
    if ! validate_domain "$DOMAIN_NAME"; then
        print_color "Warning: '$DOMAIN_NAME' doesn't look like a valid domain name. Let's Encrypt may fail." "$YELLOW"
    fi
fi

echo ""
echo "============================================="
echo "           Email Configuration                "
echo "============================================="
echo ""

# Admin email
while true; do
    read -p "Enter admin email address (for alerts): " ADMIN_EMAIL
    if validate_email "$ADMIN_EMAIL"; then
        break
    else
        print_color "Invalid email format. Please try again." "$RED"
    fi
done

echo ""
echo "============================================="
echo "           Backup Configuration              "
echo "============================================="
echo ""

# Backup directory
read -p "Enter backup directory path [/var/backups/glpi]: " BACKUP_DIR
BACKUP_DIR=${BACKUP_DIR:-/var/backups/glpi}

# Backup retention days
read -p "Enter number of days to keep backups [30]: " BACKUP_RETENTION
BACKUP_RETENTION=${BACKUP_RETENTION:-30}

# Backup time
read -p "Enter backup time (24h format, e.g., 02:00) [02:00]: " BACKUP_TIME
BACKUP_TIME=${BACKUP_TIME:-02:00}

# Summary
clear
echo "============================================="
echo "           Installation Summary               "
echo "============================================="
echo ""
echo "System Information:"
echo "  - Operating System: Debian $OS_VERSION ($OS_CODENAME)"
echo "  - PHP Version: $PHP_VERSION"
echo ""
echo "Database Configuration:"
echo "  - Database Name: $DB_NAME"
echo "  - Database User: $DB_USER"
echo "  - Database Password: [HIDDEN]"
echo ""
echo "Web Server Configuration:"
echo "  - Domain/IP: $DOMAIN_NAME"
echo "  - HTTPS: $ENABLE_HTTPS"
echo ""
echo "Email Configuration:"
echo "  - Admin Email: $ADMIN_EMAIL"
echo ""
echo "Backup Configuration:"
echo "  - Backup Directory: $BACKUP_DIR"
echo "  - Retention Days: $BACKUP_RETENTION"
echo "  - Backup Time: $BACKUP_TIME"
echo ""
echo "============================================="
read -p "Proceed with installation? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    print_color "Installation cancelled by user." "$YELLOW"
    exit 0
fi

# Start installation
log_message "Starting server setup..."
print_color "\nStarting GLPI server setup for Debian $OS_VERSION..." "$GREEN"

# Update system
log_message "Updating system packages..."
print_color "Updating system packages..." "$YELLOW"
apt update -qq 2>&1 | tee -a "$LOGFILE"
apt upgrade -y -qq 2>&1 | tee -a "$LOGFILE"

# Install SURY repo for older Debian versions
if [[ $OS_VERSION == "11" ]] || [[ $OS_VERSION == "12" ]]; then
    install_sury_repo
fi

# Install required packages
log_message "Installing required packages..."
print_color "Installing required packages..." "$YELLOW"

# Base packages (common for all versions)
apt install -y -qq \
    apache2 \
    mariadb-server \
    mariadb-client \
    wget \
    tar \
    curl \
    unzip \
    cron \
    ca-certificates \
    lsb-release \
    certbot \
    python3-certbot-apache \
    sudo 2>&1 | tee -a "$LOGFILE"

# Install PHP packages based on OS version
log_message "Installing PHP $PHP_VERSION packages..."
print_color "Installing PHP $PHP_VERSION packages..." "$YELLOW"

# Split PHP packages installation to handle failures gracefully
for pkg in $PHP_PACKAGES; do
    apt install -y -qq "$pkg" 2>&1 | tee -a "$LOGFILE" || {
        log_message "Warning: Could not install $pkg"
        print_color "Warning: Could not install $pkg" "$YELLOW"
    }
done

# Check PHP installation
if ! command -v php &> /dev/null; then
    log_message "PHP installation failed!"
    print_color "PHP installation failed. Please check logs." "$RED"
    exit 1
fi

INSTALLED_PHP_VERSION=$(php -v | head -1 | cut -d' ' -f2 | cut -d'.' -f1,2)
log_message "PHP version installed: $INSTALLED_PHP_VERSION"
print_color "PHP $INSTALLED_PHP_VERSION installed successfully" "$GREEN"

# Configure PHP
log_message "Configuring PHP settings..."
print_color "Configuring PHP..." "$YELLOW"

PHP_INI=$(find /etc/php -name "php.ini" -path "*/apache2/php.ini" 2>/dev/null | head -1)

if [ -f "$PHP_INI" ]; then
    cp "$PHP_INI" "${PHP_INI}.backup"
    
    # Update PHP settings
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI" 2>/dev/null || echo "max_execution_time = 300" >> "$PHP_INI"
    sed -i 's/^max_input_time = .*/max_input_time = 300/' "$PHP_INI" 2>/dev/null || echo "max_input_time = 300" >> "$PHP_INI"
    sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$PHP_INI" 2>/dev/null || echo "memory_limit = 256M" >> "$PHP_INI"
    sed -i 's/^post_max_size = .*/post_max_size = 100M/' "$PHP_INI" 2>/dev/null || echo "post_max_size = 100M" >> "$PHP_INI"
    sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 100M/' "$PHP_INI" 2>/dev/null || echo "upload_max_filesize = 100M" >> "$PHP_INI"
    sed -i 's/^;date.timezone =.*/date.timezone = UTC/' "$PHP_INI" 2>/dev/null || echo "date.timezone = UTC" >> "$PHP_INI"
    
    log_message "PHP configured successfully"
    print_color "PHP configured successfully!" "$GREEN"
fi

# Configure MariaDB
log_message "Configuring MariaDB..."
print_color "Configuring MariaDB..." "$YELLOW"

systemctl start mariadb
systemctl enable mariadb
sleep 3

# Generate random root password for MariaDB
MARIADB_ROOT_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c16)

# Secure MariaDB and create database
mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    log_message "Database configured successfully"
    print_color "Database configured successfully!" "$GREEN"
else
    log_message "Database configuration failed!"
    print_color "Database configuration failed!" "$RED"
    exit 1
fi

# Download GLPI
log_message "Downloading GLPI..."
print_color "Downloading GLPI..." "$YELLOW"

cd /tmp
GLPI_VERSION=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep "tag_name" | cut -d '"' -f 4 | sed 's/v//')
GLPI_URL="https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz"

log_message "Downloading GLPI ${GLPI_VERSION} from: $GLPI_URL"
wget --show-progress "$GLPI_URL" -O glpi.tgz 2>&1 | tee -a "$LOGFILE"
tar -xzf glpi.tgz 2>&1 | tee -a "$LOGFILE"

# Install GLPI
if [ -d "/var/www/html/glpi" ]; then
    mv /var/www/html/glpi "/var/www/html/glpi_backup_$(date +%Y%m%d_%H%M%S)"
fi

mv glpi /var/www/html/

# Set permissions
print_color "Setting permissions..." "$YELLOW"
chown -R www-data:www-data /var/www/html/glpi
chmod -R 755 /var/www/html/glpi

# Create necessary directories
mkdir -p /var/www/html/glpi/files/_cache
mkdir -p /var/www/html/glpi/files/_cron
mkdir -p /var/www/html/glpi/files/_dumps
mkdir -p /var/www/html/glpi/files/_graphs
mkdir -p /var/www/html/glpi/files/_lock
mkdir -p /var/www/html/glpi/files/_pictures
mkdir -p /var/www/html/glpi/files/_plugins
mkdir -p /var/www/html/glpi/files/_rss
mkdir -p /var/www/html/glpi/files/_tmp
mkdir -p /var/www/html/glpi/files/_uploads
mkdir -p /var/www/html/glpi/files/_sessions
mkdir -p /var/www/html/glpi/config

chmod -R 775 /var/www/html/glpi/files
chmod -R 775 /var/www/html/glpi/config

# Configure Apache
log_message "Configuring Apache virtual host..."
print_color "Configuring Apache virtual host..." "$YELLOW"

a2enmod rewrite
a2enmod headers
a2enmod ssl

if [[ "$ENABLE_HTTPS" =~ ^[Yy]$ ]]; then
    # HTTPS Virtual Host
    cat > /etc/apache2/sites-available/glpi.conf <<APACHECONF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    Redirect permanent / https://$DOMAIN_NAME/
</VirtualHost>

<VirtualHost *:443>
    ServerName $DOMAIN_NAME
    DocumentRoot /var/www/html/glpi/public
    
    <Directory /var/www/html/glpi/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
        
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem
</VirtualHost>
APACHECONF

    # Obtain Let's Encrypt certificate
    certbot certonly --apache -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$ADMIN_EMAIL" 2>&1 | tee -a "$LOGFILE"
else
    # HTTP only Virtual Host
    cat > /etc/apache2/sites-available/glpi.conf <<APACHECONF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    DocumentRoot /var/www/html/glpi/public
    
    <Directory /var/www/html/glpi/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
        
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
APACHECONF
fi

# Disable default site and enable GLPI site
a2dissite 000-default.conf 2>/dev/null
a2ensite glpi.conf
systemctl restart apache2

# Setup backup
log_message "Setting up backup infrastructure..."
print_color "Setting up backup infrastructure..." "$YELLOW"

mkdir -p "$BACKUP_DIR"
chmod 750 "$BACKUP_DIR"

# Create backup script
cat > /usr/local/bin/glpi_backup.sh <<'BACKUPSCRIPT'
#!/bin/bash

BACKUP_DIR="BACKUP_DIR_PLACEHOLDER"
DB_NAME="DB_NAME_PLACEHOLDER"
DB_USER="DB_USER_PLACEHOLDER"
DB_PASS="DB_PASS_PLACEHOLDER"
BACKUP_RETENTION_DAYS="BACKUP_RETENTION_PLACEHOLDER"
ADMIN_EMAIL="ADMIN_EMAIL_PLACEHOLDER"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="glpi_backup_${DATE}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
LOG_FILE="${BACKUP_DIR}/backup.log"

log_backup() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

mkdir -p "$BACKUP_PATH"

log_backup "Starting database backup..."
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "${BACKUP_PATH}/${DB_NAME}_${DATE}.sql.gz"

log_backup "Starting files backup..."
tar -czf "${BACKUP_PATH}/glpi_files_${DATE}.tar.gz" -C /var/www/html glpi 2>/dev/null

cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_PATH"

chmod 640 "${BACKUP_NAME}.tar.gz"
find "$BACKUP_DIR" -name "glpi_backup_*.tar.gz" -mtime "+$BACKUP_RETENTION_DAYS" -delete

log_backup "Backup completed: ${BACKUP_NAME}.tar.gz"

if command -v mail &> /dev/null; then
    echo "GLPI Backup completed at $(date)" | mail -s "GLPI Backup" "$ADMIN_EMAIL" 2>/dev/null
fi
BACKUPSCRIPT

# Replace placeholders
sed -i "s|BACKUP_DIR_PLACEHOLDER|$BACKUP_DIR|g" /usr/local/bin/glpi_backup.sh
sed -i "s|DB_NAME_PLACEHOLDER|$DB_NAME|g" /usr/local/bin/glpi_backup.sh
sed -i "s|DB_USER_PLACEHOLDER|$DB_USER|g" /usr/local/bin/glpi_backup.sh
sed -i "s|DB_PASS_PLACEHOLDER|$DB_PASS|g" /usr/local/bin/glpi_backup.sh
sed -i "s|BACKUP_RETENTION_PLACEHOLDER|$BACKUP_RETENTION|g" /usr/local/bin/glpi_backup.sh
sed -i "s|ADMIN_EMAIL_PLACEHOLDER|$ADMIN_EMAIL|g" /usr/local/bin/glpi_backup.sh

chmod +x /usr/local/bin/glpi_backup.sh

# Setup cron job
BACKUP_HOUR=$(echo $BACKUP_TIME | cut -d: -f1)
BACKUP_MINUTE=$(echo $BACKUP_TIME | cut -d: -f2)

(crontab -l 2>/dev/null; echo "$BACKUP_MINUTE $BACKUP_HOUR * * * /usr/local/bin/glpi_backup.sh") | crontab -

# Create info file for user
cat > /root/glpi_installation_info.txt <<INSTALLINFO
=============================================
GLPI Installation Information
=============================================
Installation Date: $(date)
GLPI Version: $GLPI_VERSION
Operating System: Debian $OS_VERSION ($OS_CODENAME)
PHP Version: $INSTALLED_PHP_VERSION

📌 GLPI URL:
   http${ENABLE_HTTPS:+s}://$DOMAIN_NAME

📊 Database Information (for GLPI web installer):
   Database Host: localhost
   Database Name: $DB_NAME
   Database User: $DB_USER
   Database Password: $DB_PASS

🔐 MariaDB Root Password:
   $MARIADB_ROOT_PASS
   (Save this for database management)

💾 Backup Configuration:
   Backup Directory: $BACKUP_DIR
   Backup Time: $BACKUP_TIME daily
   Retention: $BACKUP_RETENTION days

📁 Important Paths:
   GLPI Root: /var/www/html/glpi
   GLPI Config: /var/www/html/glpi/config
   Files Directory: /var/www/html/glpi/files
   Apache Logs: /var/log/apache2/
   Install Log: $LOGFILE

🔧 Useful Commands:
   Test backup: sudo /usr/local/bin/glpi_backup.sh
   Restart Apache: systemctl restart apache2
   Restart MariaDB: systemctl restart mariadb

=============================================
INSTALLINFO

chmod 600 /root/glpi_installation_info.txt

# Run initial backup
print_color "Running initial backup..." "$YELLOW"
/usr/local/bin/glpi_backup.sh

# Final output
clear
echo ""
echo "========================================="
echo "    Server Setup Completed!              "
echo "========================================="
echo ""
print_color "✅ Server environment has been set up successfully!" "$GREEN"
echo ""
print_color "System Information:" "$CYAN"
echo "  - Operating System: Debian $OS_VERSION ($OS_CODENAME)"
echo "  - PHP Version: $INSTALLED_PHP_VERSION"
echo "  - GLPI Version: $GLPI_VERSION"
echo ""
print_color "📌 Complete GLPI Installation via Web Browser:" "$CYAN"
echo "   URL: http${ENABLE_HTTPS:+s}://$DOMAIN_NAME"
echo ""
print_color "📊 Database Information (needed for web installer):" "$CYAN"
echo "   Database Host: localhost"
echo "   Database Name: $DB_NAME"
echo "   Database User: $DB_USER"
echo "   Database Password: $DB_PASS"
echo ""
print_color "🔐 MariaDB Root Password (for reference):" "$YELLOW"
echo "   $MARIADB_ROOT_PASS"
echo ""
print_color "📝 Next Steps:" "$GREEN"
echo "   1. Open your web browser and go to: http${ENABLE_HTTPS:+s}://$DOMAIN_NAME"
echo "   2. Follow the GLPI web installation wizard"
echo "   3. When asked for database details, use the information above"
echo "   4. After installation, remove the install directory for security:"
echo "      sudo rm -rf /var/www/html/glpi/install"
echo ""
print_color "💾 Backup Information:" "$CYAN"
echo "   Daily backups are scheduled at $BACKUP_TIME"
echo "   Backup location: $BACKUP_DIR"
echo ""
print_color "📖 All information saved to:" "$YELLOW"
echo "   /root/glpi_installation_info.txt"
echo ""
print_color "Thank you for using the GLPI installer!" "$GREEN"
echo ""

log_message "Server setup completed successfully on Debian $OS_VERSION"
