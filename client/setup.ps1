# Claude Code Metrics Client Setup for Windows
# This script configures Claude Code to send metrics to your monitoring server

Write-Host "`nClaude Code Metrics - Windows Client Configuration" -ForegroundColor Green
Write-Host "=================================================`n" -ForegroundColor Green

# Function to validate IP address or hostname
function Test-ServerAddress {
    param($Address)
    
    # Test if it's a valid IP
    try {
        [System.Net.IPAddress]::Parse($Address) | Out-Null
        return $true
    } catch {
        # Not an IP, check if it's a valid hostname
        if ($Address -match "^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?(\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?)*$") {
            return $true
        }
        return $false
    }
}

# Get configuration from user
Write-Host "Please provide the following configuration details:" -ForegroundColor Yellow
Write-Host ""

# Server address
do {
    $server = Read-Host "Enter server address (IP or hostname)"
    if (!(Test-ServerAddress $server)) {
        Write-Host "Invalid server address. Please enter a valid IP or hostname." -ForegroundColor Red
    }
} while (!(Test-ServerAddress $server))

# OTLP Port
$port = Read-Host "Enter OTLP port [default: 4317]"
if ([string]::IsNullOrWhiteSpace($port)) { 
    $port = "4317" 
}

# Validate port
if (!($port -match "^\d+$") -or [int]$port -lt 1 -or [int]$port -gt 65535) {
    Write-Host "Invalid port. Using default: 4317" -ForegroundColor Yellow
    $port = "4317"
}

# Environment
Write-Host "`nSelect environment:" -ForegroundColor Yellow
Write-Host "1. dev (Development)" -ForegroundColor Cyan
Write-Host "2. staging (Staging)" -ForegroundColor Cyan
Write-Host "3. prod (Production)" -ForegroundColor Cyan

do {
    $envChoice = Read-Host "Enter choice (1-3) [default: 1]"
    if ([string]::IsNullOrWhiteSpace($envChoice)) { $envChoice = "1" }
} while ($envChoice -notmatch "^[1-3]$")

$environment = switch ($envChoice) {
    "1" { "dev" }
    "2" { "staging" }
    "3" { "prod" }
}

# Client ID
$defaultClientId = $env:COMPUTERNAME
$clientId = Read-Host "Enter client ID [default: $defaultClientId]"
if ([string]::IsNullOrWhiteSpace($clientId)) { 
    $clientId = $defaultClientId 
}

# Privacy settings
Write-Host "`nPrivacy Settings:" -ForegroundColor Yellow
$includeSessionId = Read-Host "Include session ID in metrics? (y/N)"
$includeSessionId = if ($includeSessionId -eq "y" -or $includeSessionId -eq "Y") { "true" } else { "false" }

# Test connectivity
Write-Host "`nTesting connection to server..." -ForegroundColor Yellow
$testUrl = "http://${server}:${port}"

try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($server, [int]$port)
    $tcpClient.Close()
    Write-Host "Connection successful!" -ForegroundColor Green
} catch {
    Write-Host "Warning: Cannot connect to $testUrl" -ForegroundColor Yellow
    Write-Host "Make sure the server is running and accessible" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "Setup cancelled" -ForegroundColor Red
        exit 1
    }
}

# Create PowerShell configuration script
$psConfigContent = @"
# Claude Code Metrics Configuration
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Server: $server

# Enable telemetry
`$env:CLAUDE_CODE_ENABLE_TELEMETRY = "1"

# OpenTelemetry configuration
`$env:OTEL_SERVICE_NAME = "claude-code"
`$env:OTEL_METRICS_EXPORTER = "otlp"
`$env:OTEL_LOGS_EXPORTER = "otlp"
`$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
`$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://${server}:${port}"

# Resource attributes
`$env:OTEL_RESOURCE_ATTRIBUTES = "service.name=claude-code,environment=${environment},client.id=${clientId},os.type=windows,os.version=`$([System.Environment]::OSVersion.Version)"

# Export settings
`$env:OTEL_METRIC_EXPORT_INTERVAL = "30000"  # 30 seconds
`$env:OTEL_METRIC_EXPORT_TIMEOUT = "10000"   # 10 seconds

# Additional configuration
`$env:CLAUDE_ENV = "${environment}"
`$env:CLAUDE_CLIENT_ID = "${clientId}"
`$env:OTEL_BSP_SCHEDULE_DELAY = "5000"
`$env:OTEL_BLRP_SCHEDULE_DELAY = "5000"
`$env:OTEL_BSP_EXPORT_TIMEOUT = "30000"
`$env:OTEL_BLRP_EXPORT_TIMEOUT = "30000"

# Privacy settings
`$env:OTEL_METRICS_INCLUDE_SESSION_ID = "${includeSessionId}"

Write-Host "Claude Code metrics environment loaded" -ForegroundColor Green
Write-Host "Server: ${server}:${port}" -ForegroundColor Cyan
Write-Host "Environment: ${environment}" -ForegroundColor Cyan
Write-Host "Client ID: ${clientId}" -ForegroundColor Cyan
"@

$psConfigPath = "claude-metrics.ps1"
$psConfigContent | Out-File -FilePath $psConfigPath -Encoding UTF8 -NoNewline

# Create batch file for Command Prompt compatibility
$batchContent = @"
@echo off
REM Claude Code Metrics Configuration for Command Prompt
REM Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

REM Enable telemetry
set CLAUDE_CODE_ENABLE_TELEMETRY=1

REM OpenTelemetry configuration
set OTEL_SERVICE_NAME=claude-code
set OTEL_METRICS_EXPORTER=otlp
set OTEL_LOGS_EXPORTER=otlp
set OTEL_EXPORTER_OTLP_PROTOCOL=grpc
set OTEL_EXPORTER_OTLP_ENDPOINT=http://${server}:${port}

REM Resource attributes
set OTEL_RESOURCE_ATTRIBUTES=service.name=claude-code,environment=${environment},client.id=${clientId},os.type=windows

REM Export settings
set OTEL_METRIC_EXPORT_INTERVAL=30000
set OTEL_METRIC_EXPORT_TIMEOUT=10000

REM Additional configuration
set CLAUDE_ENV=${environment}
set CLAUDE_CLIENT_ID=${clientId}
set OTEL_BSP_SCHEDULE_DELAY=5000
set OTEL_BLRP_SCHEDULE_DELAY=5000
set OTEL_BSP_EXPORT_TIMEOUT=30000
set OTEL_BLRP_EXPORT_TIMEOUT=30000

REM Privacy settings
set OTEL_METRICS_INCLUDE_SESSION_ID=${includeSessionId}

echo Claude Code metrics environment loaded
echo Server: ${server}:${port}
echo Environment: ${environment}
echo Client ID: ${clientId}
"@

$batchPath = "claude-metrics.bat"
$batchContent | Out-File -FilePath $batchPath -Encoding ASCII -NoNewline

# Create wrapper script for PowerShell
$wrapperPsContent = @"
#!/usr/bin/env pwsh
# Claude Code with Metrics - PowerShell Wrapper

# Load metrics configuration
. "`$PSScriptRoot\claude-metrics.ps1"

# Run Claude Code with all arguments passed through
& claude-code `$args
"@

$wrapperPsPath = "claude-with-metrics.ps1"
$wrapperPsContent | Out-File -FilePath $wrapperPsPath -Encoding UTF8 -NoNewline

# Create wrapper batch file
$wrapperBatchContent = @"
@echo off
REM Claude Code with Metrics - Batch Wrapper

REM Load metrics configuration
call "%~dp0claude-metrics.bat"

REM Run Claude Code with all arguments
claude-code %*
"@

$wrapperBatchPath = "claude-with-metrics.bat"
$wrapperBatchContent | Out-File -FilePath $wrapperBatchPath -Encoding ASCII -NoNewline

# Display completion message
Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "Configuration Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

Write-Host "`nConfiguration files created:" -ForegroundColor Yellow
Write-Host "- claude-metrics.ps1     (PowerShell configuration)" -ForegroundColor Cyan
Write-Host "- claude-metrics.bat     (Command Prompt configuration)" -ForegroundColor Cyan
Write-Host "- claude-with-metrics.ps1 (PowerShell wrapper)" -ForegroundColor Cyan
Write-Host "- claude-with-metrics.bat (Command Prompt wrapper)" -ForegroundColor Cyan

Write-Host "`nTo use Claude Code with metrics:" -ForegroundColor Yellow
Write-Host "`nOption 1 - Load environment then run:" -ForegroundColor Green
Write-Host "  PowerShell:  . .\claude-metrics.ps1" -ForegroundColor White
Write-Host "               claude-code" -ForegroundColor White
Write-Host "  Cmd Prompt:  claude-metrics.bat" -ForegroundColor White
Write-Host "               claude-code" -ForegroundColor White

Write-Host "`nOption 2 - Use wrapper script:" -ForegroundColor Green
Write-Host "  PowerShell:  .\claude-with-metrics.ps1" -ForegroundColor White
Write-Host "  Cmd Prompt:  claude-with-metrics.bat" -ForegroundColor White

Write-Host "`nOption 3 - Add to PowerShell profile:" -ForegroundColor Green
Write-Host "  Add this line to your `$PROFILE:" -ForegroundColor White
Write-Host "  . `"$PWD\claude-metrics.ps1`"" -ForegroundColor Yellow

Write-Host "`nConfiguration Summary:" -ForegroundColor Cyan
Write-Host "Server:      http://${server}:${port}" -ForegroundColor White
Write-Host "Environment: ${environment}" -ForegroundColor White
Write-Host "Client ID:   ${clientId}" -ForegroundColor White

Write-Host "`nMetrics will be sent to your monitoring server when Claude Code is used." -ForegroundColor Green