FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Create OpenClaw directories
RUN mkdir -p /data/.openclaw /data/workspace
RUN chown -R node:node /data

# Switch to node user
USER node

# Set OpenClaw environment
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace

# Create app directory
WORKDIR /app

# Expose port
EXPOSE 8080

# Health check using OpenClaw's built-in endpoints
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1

# Start OpenClaw gateway (updated for Railway)
CMD ["openclaw", "gateway", "run", "--bind", "lan", "--port", "8080"]