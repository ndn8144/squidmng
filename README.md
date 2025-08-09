# Squid HTTP Proxy Manager v1.0

A professional HTTP Proxy Server management tool written in Bash for Ubuntu systems, utilizing Squid proxy server.

## 📋 Table of Contents

- [Features](#-features)
- [System Requirements](#-system-requirements) 
- [Installation](#-installation)
- [Usage](#-usage)
- [Main Functions](#-main-functions)
- [Directory Structure](#-directory-structure)
- [Configuration](#-configuration)
- [Monitoring & Status Check](#-monitoring--status-check)
- [Troubleshooting](#-troubleshooting)
- [Security](#-security)
- [FAQ](#-faq)
- [Contributing](#-contributing)

## 🚀 Features

### Basic Management
- ✅ **Automatic installation** of Squid HTTP proxy server
- ✅ **Intuitive menu interface** with colorful output
- ✅ **User management** (add/delete/list users)
- ✅ **Automatic configuration** of network interface and port
- ✅ **Complete uninstallation** when no longer needed

### Monitoring & Testing
- 📊 **System information display** (CPU, RAM, disk usage)
- 🔍 **Real-time Squid service monitoring**
- 📜 **Detailed service logs** viewing
- 🌐 **Internet bandwidth testing**
- 🧪 **HTTP proxy testing** with multiple servers

### Automation
- ⚙️ **Automatic client config generation** for each user
- 🔄 **Easy service restart/stop** functionality
- 📂 **Config file management** in separate directory
- 🛡️ **Automatic input validation**

## 🔧 System Requirements

### Operating System
- **Ubuntu 18.04+** (recommended)
- **Debian 9+** (may work)

### Required Software
- `curl` - for connectivity testing
- `netstat` - for port checking
- `systemctl` - for service management
- `htpasswd` - for user management (from apache2-utils)
- `bc` - for calculations (auto-installed if needed)

### Access Requirements
- **Root privileges** (sudo or root user)
- **Network access** for downloading packages

### System Resources
- **RAM**: Minimum 512MB (recommended 1GB+)
- **Disk**: Minimum 100MB free space
- **CPU**: Any x86_64 CPU

## 📥 Installation

### Method 1: Direct Download
```bash
# Download script
wget https://raw.githubusercontent.com/yourusername/SquidProxyManagement/main/squidManager.sh

# Make executable
chmod +x squidManager.sh

# Run script
sudo ./squidManager.sh
```

### Method 2: Clone Repository
```bash
# Clone repository
git clone https://github.com/yourusername/SquidProxyManagement.git

# Enter directory
cd SquidProxyManagement

# Make executable
chmod +x squidManager.sh

# Run script
sudo ./squidManager.sh
```

### Method 3: Direct Execution
```bash
# Run script directly from internet
curl -sSL https://raw.githubusercontent.com/yourusername/SquidProxyManagement/main/squidManager.sh | sudo bash
```

## 📘 Usage

### Starting the Script
```bash
sudo ./squidManager.sh
```

After starting, you'll see the main menu with 8 options:

```
┌─ Menu Options ───────────────────────────────────────────────────────────────┐
│ 1. Install Squid HTTP Proxy                                                  │
│ 2. Show Users                                                                │
│ 3. Add Users                                                                 │
│ 4. Delete Users                                                              │
│ 5. Test Proxies                                                              │
│ 6. Check Status & Monitoring                                                 │
│ 7. Uninstall Squid                                                           │
│ 8. Exit                                                                      │
└──────────────────────────────────────────────────────────────────────────────┘
```

## 🛠️ Main Functions

### 1. Install Squid HTTP Proxy
**Purpose**: Install and configure Squid HTTP proxy server for the first time.

**Process**:
1. Select network interface (displays list of available IPs)
2. Enter port for HTTP proxy (default: 3128)
3. Script will automatically:
   - Update package list
   - Install `squid` and `apache2-utils`
   - Create configuration file `/etc/squid/squid.conf`
   - Initialize cache directories
   - Enable and start service

**Example generated configuration**:
```bash
# /etc/squid/squid.conf
http_port 192.168.1.100:3128

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy Server
acl authenticated proxy_auth REQUIRED

# Access rules
http_access allow authenticated
http_access allow localhost
http_access deny all

# Cache configuration
cache_dir ufs /var/spool/squid 100 16 256
cache_mem 256 MB
```

### 2. Show Users
**Purpose**: Display list of all existing HTTP proxy users.

**Information displayed**:
- Sequential number
- Username
- Total user count

**User source**: Users stored in `/etc/squid/passwd` (htpasswd format)

### 3. Add Users
**Purpose**: Add new users for HTTP proxy.

**Features**:
- **Bulk user addition**: Enter list of usernames, one per line
- **Automatic validation**: Check username format, duplicates
- **Password creation**: Enter and confirm password for each user
- **Config file generation**: Create proxy configuration for each user

**Input format**:
```
# Enter usernames (one per line)
user1
user2
user3

# Press Enter twice to finish
```

**Generated config file**: `squidConfigs/[username].txt` (plain text instructions)

### 4. Delete Users
**Purpose**: Remove unnecessary HTTP proxy users.

**Features**:
- Display list of deletable users
- Select multiple users at once (space-separated numbers)
- Confirmation before deletion
- Remove both htpasswd entry and config file
- Automatic Squid reload

**Example**: Enter `1 3 5` to delete users #1, #3, and #5

### 5. Test Proxies
**Purpose**: Check operational status of HTTP proxies.

**Features**:
- **Test multiple proxies simultaneously**
- **Automatic format validation**
- **Real-time results** with progress indicator
- **Statistics**: Total proxies, successful, failed, success rate

**Input format**:
```
IP:PORT:USERNAME:PASSWORD

# Examples:
100.150.200.250:3128:user1:pass123
192.168.1.100:8080:alice:secret456
```

**Example output**:
```
┌─ Proxy Test Results ─────────────────────────────────────────────────────────┐
│ [ 1/ 3] 100.150.200.250:3128@user1     ✓ SUCCESS                             │
│ [ 2/ 3] 192.168.1.100:8080@alice       ✗ FAILED                              │
│ [ 3/ 3] 10.0.0.1:3128@bob              ✓ SUCCESS                             │
└──────────────────────────────────────────────────────────────────────────────┘

┌─ Test Summary ───────────────────────────────────────────────────────────────┐
│ Total Proxies:   3                                                           │
│ Successful:      2                                                           │
│ Failed:          1                                                           │
│ Success Rate:    66%                                                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 6. Check Status & Monitoring
**Purpose**: Monitor system and Squid service.

**Information displayed**:

#### System Information:
- **CPU Usage**: Percentage of CPU currently in use
- **Memory**: RAM used/total
- **Disk Usage**: Percentage of disk space used
- **Uptime**: System uptime

#### Squid Information:
- **Squid Status**: Running/Stopped/Failed
- **Auto-start Status**: Enabled/Disabled
- **Listen Address**: IP:Port currently listening
- **Active Connections**: Current connection count

#### Recent Service Logs:
- Last 5 log entries from the past hour

#### Control Options:
1. **Restart Service**: Restart Squid service
2. **Stop Service**: Stop Squid service  
3. **Change Port**: Modify listening port
4. **Test Internet Bandwidth**: Check network speed
5. **Full Service Logs**: View last 50 log entries
6. **Back to Main Menu**: Return to main menu

### 7. Uninstall Squid
**Purpose**: Completely uninstall Squid and clean the system.

**Process**:
1. **Warning**: Display warning about complete removal
2. **Confirmation**: Require user confirmation
3. **Stop service**: Stop and disable Squid service
4. **Remove package**: Uninstall `squid`
5. **Clean config**: Remove all configuration files
6. **Optional cleanup**: Ask about removing user config files

### 8. Exit
Exit the script with a thank you message.

## 📁 Directory Structure

```
/
├── etc/squid/
│   ├── squid.conf                  # Main Squid configuration file
│   └── passwd                      # HTTP Basic Auth password file
├── var/log/squid/
│   ├── access.log                  # Access logs
│   └── cache.log                   # Cache and error logs
├── var/spool/squid/                # Cache directory
└── [script_directory]/
    ├── squidManager.sh             # Main script
    └── squidConfigs/               # Directory containing config files
        ├── user1.txt               # HTTP proxy config for user1
        ├── user2.txt               # HTTP proxy config for user2
        └── ...
```

## ⚙️ Configuration

### Squid Configuration File (`/etc/squid/squid.conf`)

```bash
# Port configuration
http_port [SERVER_IP]:[PORT]

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy Server
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED

# Access control lists
acl localnet src 192.168.0.0/16
acl SSL_ports port 443
acl Safe_ports port 80 443 21 70 210 1025-65535 280 488 591 777
acl CONNECT method CONNECT

# Access rules
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow authenticated
http_access allow localnet
http_access allow localhost
http_access deny all

# Cache configuration
cache_dir ufs /var/spool/squid 100 16 256
cache_mem 256 MB
maximum_object_size 1024 MB

# Privacy settings
forwarded_for delete
via off
```

### User Password File (`/etc/squid/passwd`)
```
user1:$apr1$salt$hashedpassword
user2:$apr1$salt$hashedpassword
```

### User Configuration File (Example)
Each user will have a configuration file in `squidConfigs/[username].txt`:

```
# HTTP Proxy Configuration for user1
# Use these settings in your HTTP proxy client

Proxy Type: HTTP
Server: 192.168.1.100
Port: 3128
Username: user1
Password: password123

# Example curl command:
curl --proxy http://user1:password123@192.168.1.100:3128 http://httpbin.org/ip

# Browser proxy settings:
# HTTP Proxy: 192.168.1.100:3128
# Username: user1
# Password: password123
```

## 📊 Monitoring & Status Check

### Checking Service Status
```bash
# Check status
sudo systemctl status squid

# View real-time logs
sudo journalctl -u squid -f

# Check listening port
sudo netstat -tlnp | grep squid
```

### Checking Users
```bash
# View user list
cat /etc/squid/passwd

# Test authentication
htpasswd -v /etc/squid/passwd username
```

### Checking Connections
```bash
# Check active connections
sudo ss -tn | grep :[PORT]

# Test proxy with curl
curl --proxy http://username:password@server_ip:port http://httpbin.org/ip
```

### Access Logs
```bash
# Real-time access monitoring
sudo tail -f /var/log/squid/access.log

# Check for errors
sudo tail -f /var/log/squid/cache.log
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Service Won't Start
**Symptoms**: Squid service failed to start
```bash
# Check logs
sudo journalctl -u squid --no-pager -n 20

# Check configuration syntax
sudo squid -k parse
```

**Solutions**:
- Verify IP address in config is correct
- Check for port conflicts
- Verify config file syntax

#### 2. Port Already in Use
**Symptoms**: Port already in use error
```bash
# Check which process is using the port
sudo lsof -i :[PORT]
sudo netstat -tlnp | grep :[PORT]
```

**Solutions**:
- Choose a different port
- Kill the process using the port (if safe)

#### 3. Authentication Failed
**Symptoms**: Client can't connect with username/password

**Check**:
```bash
# Verify user exists
grep "^username:" /etc/squid/passwd

# Test password
htpasswd -v /etc/squid/passwd username
```

**Solutions**:
- Recreate user with new password
- Check htpasswd file permissions
- Verify auth_param configuration

#### 4. Cache Issues
**Symptoms**: Cache errors in logs

**Solutions**:
```bash
# Reinitialize cache directories
sudo squid -z

# Check cache directory permissions
sudo chown -R proxy:proxy /var/spool/squid
```

### Debug Mode

To run Squid in debug mode:
```bash
# Stop service first
sudo systemctl stop squid

# Run manually with debug
sudo squid -N -d1
```

## 🔒 Security

### Security Recommendations

#### 1. Firewall Configuration
```bash
# Only allow HTTP proxy port
sudo ufw allow [PROXY_PORT]/tcp

# Allow SSH (if needed)
sudo ufw allow 22

# Block all other ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
```

#### 2. Strong Passwords
- Use passwords with at least 8 characters
- Combine uppercase, lowercase, numbers, and special characters
- Avoid personal information

#### 3. Access Control
```bash
# Limit access from specific networks (in squid.conf)
acl allowed_networks src 192.168.1.0/24
http_access allow allowed_networks authenticated
```

#### 4. SSL/TLS Proxy (Optional)
```bash
# Add HTTPS support (advanced configuration)
https_port 3129 cert=/path/to/cert.pem key=/path/to/key.pem
```

### Backup and Restore

#### Backup Configuration
```bash
# Backup Squid config
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.backup

# Backup password file
sudo cp /etc/squid/passwd /etc/squid/passwd.backup

# Backup user configs
tar -czf squidConfigs_backup.tar.gz squidConfigs/
```

#### Restore
```bash
# Restore Squid config
sudo cp /etc/squid/squid.conf.backup /etc/squid/squid.conf

# Restore password file
sudo cp /etc/squid/passwd.backup /etc/squid/passwd

# Restart service
sudo systemctl restart squid
```

## ❓ FAQ

### Q: Does the script work on CentOS/RHEL?
**A**: The script is designed for Ubuntu/Debian. For CentOS/RHEL, modify:
- `apt` → `yum` or `dnf`
- Package name might be different
- Service management is similar

### Q: Can I use HTTPS proxying?
**A**: Basic HTTP proxy is configured by default. For HTTPS tunneling (CONNECT method), it's already supported. For SSL bumping, additional configuration is needed.

### Q: How do I change the cache size?
**A**: Edit `/etc/squid/squid.conf`:
```bash
cache_dir ufs /var/spool/squid [SIZE_MB] 16 256
cache_mem [MEMORY_MB] MB
```

### Q: Can I disable authentication?
**A**: Yes, but not recommended. Comment out auth lines and change:
```bash
# http_access allow authenticated
http_access allow localnet
```

### Q: How to monitor bandwidth usage?
**A**: Check access logs:
```bash
sudo tail -f /var/log/squid/access.log
# Or use tools like: squidanalyzer, sarg, or lightsquid
```

### Q: Maximum number of concurrent connections?
**A**: Default is usually sufficient. To increase:
```bash
# Add to squid.conf
http_port [IP]:[PORT] connections=1000
```

## 🤝 Contributing

### Reporting Bugs
1. Open an issue on GitHub
2. Provide information:
   - OS version
   - Error messages
   - Steps to reproduce
   - Expected vs actual behavior

### Feature Requests
1. Check existing issues first
2. Describe the use case in detail
3. Suggest implementation approach

### Pull Requests
1. Fork the repository
2. Create a feature branch
3. Commit changes with clear messages
4. Submit pull request with description

---

## 📞 Support

- **GitHub Issues**: [Report bugs/feature requests]
- **Email**: [Contact maintainer]
- **Documentation**: Check Squid official docs at http://www.squid-cache.org/

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

- **Squid Proxy Server**: [The Squid Software Foundation](http://www.squid-cache.org/)
- **Apache2-utils**: For htpasswd utility
- **Contributors**: All those who have contributed to this project

---

**⚠️ Disclaimer**: This script is provided "as-is" without warranty. Use at your own responsibility and comply with local laws regarding proxy usage.