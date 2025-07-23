#!/bin/bash

# Claude Code Metrics Client Setup Script
# This script configures Claude Code to send metrics to your central monitoring server

set -e

echo "Claude Code Metrics Client Setup"
echo "================================"

# Default values
DEFAULT_SERVER="localhost"
DEFAULT_PORT="4317"
DEFAULT_ENV="development"
DEFAULT_CLIENT_ID=$(hostname)

# Prompt for configuration
read -p "Enter monitoring server address [$DEFAULT_SERVER]: " SERVER_ADDRESS
SERVER_ADDRESS=${SERVER_ADDRESS:-$DEFAULT_SERVER}

read -p "Enter OTLP port [$DEFAULT_PORT]: " OTLP_PORT
OTLP_PORT=${OTLP_PORT:-$DEFAULT_PORT}

read -p "Enter environment name (dev/staging/prod) [$DEFAULT_ENV]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-$DEFAULT_ENV}

read -p "Enter client identifier [$DEFAULT_CLIENT_ID]: " CLIENT_ID
CLIENT_ID=${CLIENT_ID:-$DEFAULT_CLIENT_ID}

# Create environment configuration file
ENV_FILE="claude-metrics.env"

cat > "$ENV_FILE" << EOF
# Claude Code Metrics Configuration
# Source this file before running Claude Code

# Enable telemetry
export CLAUDE_CODE_ENABLE_TELEMETRY=1

# OpenTelemetry Configuration
export OTEL_SERVICE_NAME="claude-code"
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://${SERVER_ADDRESS}:${OTLP_PORT}

# Custom attributes for identification
export OTEL_RESOURCE_ATTRIBUTES="environment=${ENVIRONMENT},client_id=${CLIENT_ID},host=$(hostname)"

# Optional: Adjust export intervals (in milliseconds)
export OTEL_METRIC_EXPORT_INTERVAL=30000
export OTEL_METRIC_EXPORT_TIMEOUT=10000

# Privacy settings
export OTEL_METRICS_INCLUDE_SESSION_ID=false
export OTEL_METRICS_INCLUDE_VERSION=true
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=false

# Additional Claude Code settings
export CLAUDE_ENV="${ENVIRONMENT}"
export CLAUDE_CLIENT_ID="${CLIENT_ID}"
EOF

echo ""
echo "Configuration file created: $ENV_FILE"
echo ""
echo "To use this configuration:"
echo "1. Source the environment file:"
echo "   source $ENV_FILE"
echo ""
echo "2. Run Claude Code as normal"
echo ""
echo "3. (Optional) Add to your shell profile for persistence:"
echo "   echo 'source $(pwd)/$ENV_FILE' >> ~/.bashrc"
echo ""
echo "Metrics will be sent to: http://${SERVER_ADDRESS}:${OTLP_PORT}"
echo ""

# Create a wrapper script for convenience
WRAPPER_SCRIPT="claude-with-metrics"

cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash
# Claude Code wrapper with metrics enabled

# Find the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the environment configuration
source "$SCRIPT_DIR/claude-metrics.env"

# Run Claude Code with all arguments passed through
claude-code "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"

echo "Created wrapper script: $WRAPPER_SCRIPT"
echo "You can use './$WRAPPER_SCRIPT' instead of 'claude-code' to run with metrics enabled"
echo ""
echo "Setup complete!"