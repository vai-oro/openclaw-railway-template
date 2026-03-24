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

# Point OpenClaw at our state/config dir
ENV OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json

# Run non-interactive onboarding at build time to create a fully configured gateway
# --skip-health: no running gateway during build
# --auth-choice venice-api-key: Venice provider (key from env at runtime)
# --secret-input-mode ref: store API key as env ref, not plaintext
# --gateway-auth token: token-based auth
# --gateway-token-ref-env: store gateway token as env ref
RUN VENICE_API_KEY="placeholder" \
    OPENCLAW_GATEWAY_TOKEN="placeholder" \
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice venice-api-key \
      --secret-input-mode ref \
      --gateway-auth token \
      --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
      --gateway-bind lan \
      --skip-health \
      --accept-risk

# Override default model to claude-sonnet-4-6 (onboard defaults to kimi-k2-5)
RUN openclaw config set agents.defaults.model.primary venice/claude-sonnet-4-6

# Start OpenClaw gateway in foreground
CMD ["openclaw", "gateway", "run", "--bind", "lan"]
