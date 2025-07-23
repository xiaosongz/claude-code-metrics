# Claude Code Metrics Windows Setup Script
# Run this script in PowerShell as Administrator

Write-Host "`nClaude Code Metrics - Windows Server Setup" -ForegroundColor Green
Write-Host "=========================================`n" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check Docker
Write-Host "Checking Docker installation..." -ForegroundColor Yellow
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop for Windows from:" -ForegroundColor Yellow
    Write-Host "https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host "`nAfter installation, restart this script" -ForegroundColor Yellow
    exit 1
}

# Check Docker Compose
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker Compose is not installed" -ForegroundColor Red
    Write-Host "Docker Desktop should include Docker Compose" -ForegroundColor Yellow
    exit 1
}

# Display Docker version
Write-Host "Docker version:" -ForegroundColor Green
docker --version
docker-compose --version

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "`nERROR: Docker is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again" -ForegroundColor Yellow
    exit 1
}

# Create .env file if it doesn't exist
if (!(Test-Path .env)) {
    Write-Host "`nCreating .env configuration file..." -ForegroundColor Yellow
    
    # Generate secure random password
    Add-Type -AssemblyName System.Web
    $password = [System.Web.Security.Membership]::GeneratePassword(20, 5)
    
    # Create .env content
    $envContent = @"
# Grafana Configuration
GRAFANA_USER=admin
GRAFANA_PASSWORD=$password

# Prometheus Configuration
PROMETHEUS_RETENTION_TIME=90d
PROMETHEUS_RETENTION_SIZE=10GB

# OpenTelemetry Collector Ports
OTEL_COLLECTOR_GRPC_PORT=4317
OTEL_COLLECTOR_HTTP_PORT=4318

# Grafana Settings
GRAFANA_PORT=3000
GRAFANA_DOMAIN=localhost

# Security Settings
ENABLE_BASIC_AUTH=false
ENABLE_TLS=false
"@
    
    $envContent | Out-File -FilePath .env -Encoding UTF8 -NoNewline
    
    Write-Host "`nGrafana admin credentials:" -ForegroundColor Green
    Write-Host "Username: admin" -ForegroundColor Yellow
    Write-Host "Password: $password" -ForegroundColor Yellow
    Write-Host "`nIMPORTANT: Save this password! It won't be shown again." -ForegroundColor Red
    Write-Host "Password is also saved in .env file" -ForegroundColor Cyan
} else {
    Write-Host "`n.env file already exists, skipping creation" -ForegroundColor Green
}

# Pull Docker images
Write-Host "`nPulling Docker images (this may take a few minutes)..." -ForegroundColor Yellow
docker-compose pull

# Start services
Write-Host "`nStarting Docker services..." -ForegroundColor Green
docker-compose up -d

# Wait for services to start
Write-Host "`nWaiting for services to initialize..." -ForegroundColor Yellow
$services = @("prometheus", "grafana", "otel-collector")
$maxWait = 30
$waited = 0

while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 2
    $waited += 2
    
    $allHealthy = $true
    foreach ($service in $services) {
        $status = docker ps --filter "name=$service" --format "table {{.Status}}" | Select-Object -Skip 1
        if ($status -notlike "*healthy*" -and $status -notlike "*Up*") {
            $allHealthy = $false
            break
        }
    }
    
    if ($allHealthy) {
        Write-Host "All services are running!" -ForegroundColor Green
        break
    }
    
    Write-Host "." -NoNewline
}

Write-Host ""

# Check service status
Write-Host "`nService Status:" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
docker-compose ps

# Configure Windows Firewall
Write-Host "`nConfiguring Windows Firewall..." -ForegroundColor Yellow
$rules = @(
    @{DisplayName="Claude Metrics - Grafana"; Port=3000; Name="ClaudeMetrics_Grafana"},
    @{DisplayName="Claude Metrics - OTLP gRPC"; Port=4317; Name="ClaudeMetrics_OTLP"},
    @{DisplayName="Claude Metrics - Prometheus"; Port=9090; Name="ClaudeMetrics_Prometheus"}
)

foreach ($rule in $rules) {
    # Remove existing rule if present
    Remove-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue
    
    # Add new rule
    New-NetFirewallRule -DisplayName $rule.DisplayName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $rule.Port `
        -Action Allow `
        -Name $rule.Name | Out-Null
    
    Write-Host "Added firewall rule for port $($rule.Port)" -ForegroundColor Green
}

# Get local IP address
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1).IPAddress

# Display access information
Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "`nAccess URLs:" -ForegroundColor Cyan
Write-Host "Grafana Dashboard: http://localhost:3000" -ForegroundColor Yellow
Write-Host "                   http://${localIP}:3000" -ForegroundColor Yellow
Write-Host "Prometheus:        http://localhost:9090" -ForegroundColor Yellow
Write-Host "                   http://${localIP}:9090" -ForegroundColor Yellow
Write-Host "`nOTLP Endpoint:     http://${localIP}:4317" -ForegroundColor Yellow
Write-Host "`nDefault Login:     admin / [check .env file]" -ForegroundColor Cyan

# Health check
Write-Host "`nPerforming health check..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "Grafana is healthy!" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Grafana may still be starting up" -ForegroundColor Yellow
    Write-Host "Wait a few more seconds and try accessing the URLs above" -ForegroundColor Yellow
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Access Grafana at http://localhost:3000" -ForegroundColor White
Write-Host "2. Login with admin credentials from .env file" -ForegroundColor White
Write-Host "3. Configure clients to send metrics to http://${localIP}:4317" -ForegroundColor White
Write-Host "4. View the 'Claude Code Usage Overview' dashboard" -ForegroundColor White

Write-Host "`nTo stop services: docker-compose down" -ForegroundColor Gray
Write-Host "To view logs: docker-compose logs -f" -ForegroundColor Gray