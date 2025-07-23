#!/bin/bash

# Claude Code Metrics Server Setup Script
# Run this on your Ubuntu server to set up the monitoring stack

set -e

echo "Claude Code Metrics Server Setup"
echo "================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed. Please log out and back in for group changes to take effect."
    echo "Then run this script again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    
    # Generate a random password for Grafana
    GRAFANA_PASS=$(openssl rand -base64 12)
    sed -i "s/your-secure-password/$GRAFANA_PASS/g" .env
    
    echo ""
    echo "Generated Grafana admin password: $GRAFANA_PASS"
    echo "Please save this password securely!"
    echo ""
fi

# Start the stack
echo "Starting the monitoring stack..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check service status
echo ""
echo "Service Status:"
echo "---------------"
docker-compose ps

# Get the server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "Setup Complete!"
echo "==============="
echo ""
echo "Grafana URL: http://$SERVER_IP:3000"
echo "Prometheus URL: http://$SERVER_IP:9090"
echo "OTLP Endpoint: $SERVER_IP:4317"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop services: docker-compose down"
echo "To update services: docker-compose pull && docker-compose up -d"
echo ""
echo "Next steps:"
echo "1. Access Grafana and change the admin password"
echo "2. Configure clients to send metrics to $SERVER_IP:4317"
echo "3. View the 'Claude Code Usage Overview' dashboard"