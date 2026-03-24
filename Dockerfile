FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Create OpenClaw directories
RUN mkdir -p /data/.openclaw /data/workspace && chown -R node:node /data

# Switch to non-root user
USER node

WORKDIR /app

# Copy config into state dir
COPY --chown=node:node config.json /data/.openclaw/openclaw.json

# Point OpenClaw at our config
ENV OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json

# Start OpenClaw gateway in foreground
CMD ["openclaw", "gateway", "run", "--bind", "lan", "--allow-unconfigured"]
