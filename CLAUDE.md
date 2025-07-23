# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a centralized monitoring solution for tracking Claude Code usage across multiple environments. It uses OpenTelemetry, Prometheus, and Grafana to collect and visualize metrics from distributed Claude Code installations.

Architecture: `Claude Code Clients → OpenTelemetry Collector → Prometheus → Grafana`

## Common Commands

### Server Operations
```bash
# Initial setup (installs Docker if needed)
./server-setup.sh

# Start monitoring stack
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Update services
docker-compose pull && docker-compose up -d
```

### Client Configuration
```bash
# Configure client
cd client
./setup.sh

# Use Claude Code with metrics
source claude-metrics.env
claude-code

# Or use the wrapper
./claude-with-metrics
```

## Key Configuration Files

- **docker-compose.yml**: Orchestrates the server stack (Grafana, Prometheus, OpenTelemetry Collector)
- **server/otel-collector-config.yml**: Defines how metrics are received and processed
- **server/prometheus/prometheus.yml**: Configures metric scraping and storage
- **server/grafana/dashboards/claude-code-overview.json**: Pre-built dashboard definition
- **.env**: Environment variables for server configuration (create from .env.example)

## Architecture Notes

The system collects four main metric types:
1. **Session Metrics**: Track active development sessions and duration
2. **Code Metrics**: Monitor lines of code written/modified
3. **Cost Metrics**: Track API usage costs by model and client
4. **Tool Usage**: Count tool executions and performance

Metrics flow through OpenTelemetry Protocol (OTLP) on port 4317, are stored in Prometheus with 90-day retention, and visualized in Grafana on port 3000.

## Development Guidelines

- Server components run in Docker containers for consistency
- Client configuration is done via environment variables to avoid modifying Claude Code itself
- The system is designed to be privacy-conscious - sensitive data can be excluded via configuration
- When modifying dashboards, export from Grafana UI and update the JSON files
- Test client connectivity with: `curl -f http://your-server:4317/v1/metrics || echo "Connection failed"`