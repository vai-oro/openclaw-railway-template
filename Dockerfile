FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Create app directory
WORKDIR /app

# Expose port
EXPOSE 8080

# Health check using OpenClaw's built-in endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD openclaw gateway status --require-rpc --timeout 5000 || exit 1

# Start OpenClaw gateway
CMD ["openclaw", "gateway", "start", "--non-interactive"]