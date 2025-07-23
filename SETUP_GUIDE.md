# Claude Code Metrics - Platform Setup Guide

This guide provides detailed instructions for setting up the Claude Code Metrics monitoring system on macOS, Ubuntu, and Windows.

## Table of Contents
- [Prerequisites by Platform](#prerequisites-by-platform)
- [macOS Setup](#macos-setup)
- [Ubuntu Setup](#ubuntu-setup)
- [Windows Setup](#windows-setup)
- [Client Configuration (All Platforms)](#client-configuration-all-platforms)
- [Verification Steps](#verification-steps)
- [Troubleshooting](#troubleshooting)

## Prerequisites by Platform

### macOS Prerequisites

1. **Operating System**: macOS 10.15 (Catalina) or later
2. **Hardware**: Apple Silicon (M1/M2) or Intel processor with virtualization support
3. **Software Requirements**:
   - Docker Desktop for Mac (includes Docker Compose)
   - Git (comes with Xcode Command Line Tools)
   - Terminal access
4. **Network Requirements**:
   - Internet connection for downloading Docker images
   - Ports 3000, 4317, and 9090 available
5. **Permissions**: Admin access for Docker installation

### Ubuntu Prerequisites

1. **Operating System**: Ubuntu 20.04 LTS or later (also works on Debian 10+)
2. **Hardware**: x86_64 processor with virtualization support
3. **Software Requirements**:
   - curl or wget
   - Git
   - sudo privileges
4. **Network Requirements**:
   - Internet connection for downloading packages
   - Ports 3000, 4317, and 9090 available
5. **Minimum Resources**:
   - 2GB RAM (4GB recommended)
   - 10GB free disk space

### Windows Prerequisites

1. **Operating System**: Windows 10 Pro/Enterprise (Build 19041+) or Windows 11
2. **Hardware**: 64-bit processor with virtualization support (Intel VT-x or AMD-V)
3. **Software Requirements**:
   - Docker Desktop for Windows
   - WSL2 (Windows Subsystem for Linux 2)
   - Git for Windows
   - PowerShell 5.1 or later
4. **Network Requirements**:
   - Internet connection
   - Windows Firewall exceptions for ports 3000, 4317, and 9090
5. **BIOS Settings**: Virtualization must be enabled

## macOS Setup

### Step 1: Install Docker Desktop

```bash
# Download Docker Desktop from Docker Hub
# https://www.docker.com/products/docker-desktop/

# Or use Homebrew
brew install --cask docker

# Start Docker Desktop from Applications
open /Applications/Docker.app
```

### Step 2: Verify Installation

```bash
# Verify Docker
docker --version

# Verify Docker Compose
docker-compose --version

# Verify Git
git --version
```

### Step 3: Clone Repository

```bash
# Clone the repository
git clone https://github.com/xiaosongz/claude-code-metrics.git
cd claude-code-metrics
```

### Step 4: Run Server Setup

```bash
# Make setup script executable
chmod +x server-setup.sh

# Run the setup
./server-setup.sh
```

### Step 5: Access Services

- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

## Ubuntu Setup

### Step 1: Update System

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y curl git
```

### Step 2: Install Docker (if not installed)

```bash
# The setup script will install Docker if needed
# Or install manually:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

### Step 3: Clone Repository

```bash
# Clone the repository
git clone https://github.com/xiaosongz/claude-code-metrics.git
cd claude-code-metrics
```

### Step 4: Run Server Setup

```bash
# Make setup script executable
chmod +x server-setup.sh

# Run the setup
./server-setup.sh
```

### Step 5: Configure Firewall (if enabled)

```bash
# Allow required ports
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 4317/tcp  # OTLP gRPC
sudo ufw allow 9090/tcp  # Prometheus
```

### Step 6: Access Services

- Grafana: http://your-server-ip:3000 (admin/admin)
- Prometheus: http://your-server-ip:9090

## Windows Setup

### Step 1: Install Prerequisites

1. **Install WSL2**:
```powershell
# Run as Administrator
wsl --install

# Restart computer
# Set WSL2 as default
wsl --set-default-version 2
```

2. **Install Docker Desktop**:
- Download from: https://www.docker.com/products/docker-desktop/
- During installation, ensure "Use WSL 2 instead of Hyper-V" is checked
- Start Docker Desktop after installation

3. **Install Git for Windows**:
- Download from: https://git-scm.com/download/win
- Use default settings during installation

### Step 2: Clone Repository

```powershell
# Open PowerShell or Git Bash
git clone https://github.com/xiaosongz/claude-code-metrics.git
cd claude-code-metrics
```

### Step 3: Create Windows Setup Script

Create a file `server-setup.ps1`:

```powershell
# Claude Code Metrics Windows Setup Script

Write-Host "Claude Code Metrics - Windows Setup" -ForegroundColor Green

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop and restart this script"
    exit 1
}

# Check Docker Compose
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker Compose is not installed" -ForegroundColor Red
    exit 1
}

# Create .env file if it doesn't exist
if (!(Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    
    # Generate random password
    $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 20 | ForEach-Object {[char]$_})
    
    @"
GRAFANA_USER=admin
GRAFANA_PASSWORD=$password
PROMETHEUS_RETENTION_TIME=90d
PROMETHEUS_RETENTION_SIZE=10GB
"@ | Out-File -FilePath .env -Encoding UTF8
    
    Write-Host "Generated Grafana admin password: $password" -ForegroundColor Yellow
    Write-Host "Please save this password!" -ForegroundColor Yellow
}

# Start services
Write-Host "Starting Docker services..." -ForegroundColor Green
docker-compose up -d

# Wait for services
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check services
Write-Host "`nService Status:" -ForegroundColor Green
docker-compose ps

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "Grafana: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Prometheus: http://localhost:9090" -ForegroundColor Cyan
```

### Step 4: Run Setup

```powershell
# Run the setup script
.\server-setup.ps1

# Or use docker-compose directly
docker-compose up -d
```

### Step 5: Configure Windows Firewall

```powershell
# Run as Administrator
# Allow ports through Windows Firewall
New-NetFirewallRule -DisplayName "Claude Metrics Grafana" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
New-NetFirewallRule -DisplayName "Claude Metrics OTLP" -Direction Inbound -Protocol TCP -LocalPort 4317 -Action Allow
New-NetFirewallRule -DisplayName "Claude Metrics Prometheus" -Direction Inbound -Protocol TCP -LocalPort 9090 -Action Allow
```

## Client Configuration (All Platforms)

### macOS/Linux Client Setup

```bash
cd client
chmod +x setup.sh
./setup.sh

# Follow prompts to configure:
# - Server address
# - Environment (dev/staging/prod)
# - Client ID

# Source the configuration
source claude-metrics.env

# Use Claude Code with metrics
claude-code
```

### Windows Client Setup

Create `client\setup.ps1`:

```powershell
# Claude Code Metrics Client Setup for Windows

Write-Host "Claude Code Metrics - Client Configuration" -ForegroundColor Green

# Get configuration
$server = Read-Host "Enter server address (e.g., 192.168.1.100)"
$port = Read-Host "Enter OTLP port (default: 4317)"
$environment = Read-Host "Enter environment (dev/staging/prod)"
$clientId = Read-Host "Enter client ID (default: $env:COMPUTERNAME)"

if ([string]::IsNullOrEmpty($port)) { $port = "4317" }
if ([string]::IsNullOrEmpty($clientId)) { $clientId = $env:COMPUTERNAME }

# Create configuration file
@"
`$env:CLAUDE_CODE_ENABLE_TELEMETRY = "1"
`$env:OTEL_SERVICE_NAME = "claude-code"
`$env:OTEL_METRICS_EXPORTER = "otlp"
`$env:OTEL_LOGS_EXPORTER = "otlp"
`$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
`$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://${server}:${port}"
`$env:OTEL_RESOURCE_ATTRIBUTES = "service.name=claude-code,environment=${environment},client.id=${clientId}"
`$env:OTEL_METRIC_EXPORT_INTERVAL = "30000"
`$env:OTEL_METRIC_EXPORT_TIMEOUT = "10000"
`$env:CLAUDE_ENV = "${environment}"
`$env:CLAUDE_CLIENT_ID = "${clientId}"
"@ | Out-File -FilePath claude-metrics.ps1 -Encoding UTF8

Write-Host "`nConfiguration saved to claude-metrics.ps1" -ForegroundColor Green
Write-Host "To use: . .\claude-metrics.ps1" -ForegroundColor Yellow
```

Run the setup:
```powershell
cd client
.\setup.ps1

# Load configuration
. .\claude-metrics.ps1

# Run Claude Code
claude-code
```

## Verification Steps

### 1. Verify Docker Services

All platforms:
```bash
docker-compose ps
```

Expected output: All services should show as "Up"

### 2. Test Grafana Access

- Open browser to http://localhost:3000
- Login with admin/[your-password]
- Navigate to Dashboards -> Claude Code Usage Overview

### 3. Test Client Connectivity

macOS/Linux:
```bash
curl -f http://your-server:4317/v1/metrics || echo "Connection failed"
```

Windows PowerShell:
```powershell
try {
    Invoke-WebRequest -Uri "http://your-server:4317/v1/metrics" -UseBasicParsing
    Write-Host "Connection successful" -ForegroundColor Green
} catch {
    Write-Host "Connection failed" -ForegroundColor Red
}
```

### 4. Verify Metrics Collection

1. Run Claude Code with telemetry enabled
2. Wait 1-2 minutes
3. Check Prometheus: http://localhost:9090
4. Query for `claude_code_session_count`

## Troubleshooting

### Common Issues - All Platforms

1. **Port Already in Use**
   ```bash
   # Find process using port
   lsof -i :3000  # macOS/Linux
   netstat -ano | findstr :3000  # Windows
   
   # Change port in docker-compose.yml
   ```

2. **Docker Services Won't Start**
   ```bash
   # Check logs
   docker-compose logs -f
   
   # Reset everything
   docker-compose down -v
   docker-compose up -d
   ```

3. **No Metrics Appearing**
   - Verify CLAUDE_CODE_ENABLE_TELEMETRY=1
   - Check firewall settings
   - Verify correct server endpoint
   - Check time sync between client and server

### macOS-Specific Issues

1. **Docker Desktop Not Starting**
   - Check virtualization in System Information
   - Reset Docker Desktop to factory defaults
   - Ensure enough disk space

2. **Permission Denied**
   ```bash
   # Fix permissions
   sudo chown -R $(whoami) ~/.docker
   ```

### Ubuntu-Specific Issues

1. **Docker Permission Denied**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

2. **Firewall Blocking Connections**
   ```bash
   # Check firewall status
   sudo ufw status
   # Allow Docker
   sudo ufw allow from 172.16.0.0/12
   ```

### Windows-Specific Issues

1. **WSL2 Not Working**
   - Enable virtualization in BIOS
   - Run Windows Update
   - Reinstall WSL2: `wsl --install --web-download`

2. **Docker Desktop Issues**
   - Switch between WSL2 and Hyper-V backend
   - Reset Docker Desktop settings
   - Check Windows Features: Hyper-V, WSL2

3. **PowerShell Script Execution**
   ```powershell
   # Allow script execution
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## Security Considerations

1. **Change Default Passwords**: Always change the default Grafana password
2. **Network Security**: Use VPN or secure tunnels for remote access
3. **Firewall Rules**: Only open required ports to trusted networks
4. **TLS/HTTPS**: Enable TLS for production deployments
5. **Access Control**: Implement proper authentication for all services

## Next Steps

1. Configure alerts in Prometheus
2. Create custom Grafana dashboards
3. Set up data retention policies
4. Integrate with existing monitoring systems
5. Configure automated backups