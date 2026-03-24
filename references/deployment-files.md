# Deployment File Templates

Exact file contents for a working Railway OpenClaw deployment. Copy these as-is.

## Dockerfile

```dockerfile
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
```

## config.json

```json
{
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token"
    },
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true,
      "dangerouslyDisableDeviceAuth": true
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing"
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "venice/claude-sonnet-4-6"
      }
    }
  }
}
```

### Config explained

- `gateway.mode: "local"` — run as standalone gateway
- `gateway.auth.mode: "token"` — authenticate with gateway token only (no device pairing)
- `controlUi.dangerouslyAllowHostHeaderOriginFallback` — required because Railway terminates TLS at their reverse proxy, so browser Origin headers don't match what OpenClaw expects
- `controlUi.dangerouslyDisableDeviceAuth` — required because Railway is headless (no terminal to approve device pairing)
- `channels.telegram.enabled` — activates the Telegram channel plugin
- `channels.telegram.dmPolicy` — `"pairing"` requires approval for new users, `"open"` allows anyone
- `agents.defaults.model.primary` — default inference model; requires matching provider API key in env vars

### Customizing the model

Replace `venice/claude-sonnet-4-6` with any supported model. Ensure the corresponding provider API key env var is set:

| Provider | Env var | Example model |
|----------|---------|---------------|
| Venice | `VENICE_API_KEY` | `venice/claude-sonnet-4-6` |
| Anthropic | `ANTHROPIC_API_KEY` | `anthropic/claude-sonnet-4-6` |
| OpenAI | `OPENAI_API_KEY` | `openai/gpt-4o` |
| Google | `GOOGLE_GENERATIVE_AI_API_KEY` | `google/gemini-2.5-pro` |
| Groq | `GROQ_API_KEY` | `groq/llama-3.3-70b` |
| Mistral | `MISTRAL_API_KEY` | `mistral/mistral-large-latest` |
| OpenRouter | `OPENROUTER_API_KEY` | `openrouter/auto` |
| xAI | `XAI_API_KEY` | `xai/grok-3` |

## railway.json

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "dockerfile",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "restartPolicyType": "on_failure",
    "restartPolicyMaxRetries": 3,
    "volumes": [
      {
        "name": "openclaw-data",
        "mountPath": "/data"
      }
    ]
  }
}
```

### railway.json explained

- `builder: "dockerfile"` — use our Dockerfile, not Nixpacks
- `restartPolicyType: "on_failure"` — auto-restart crashed containers (up to 3 times)
- `volumes` — persistent storage at `/data` so config and state survive redeploys

## Required Railway Environment Variables

```bash
VENICE_API_KEY=<your-venice-api-key>           # Provider auth (set BEFORE first deploy)
TELEGRAM_BOT_TOKEN=<your-bot-token>            # From @BotFather on Telegram (/newbot)
OPENCLAW_GATEWAY_TOKEN=<random-hex-string>     # Control UI auth
OPENCLAW_GATEWAY_PORT=8080                     # OpenClaw port binding
PORT=8080                                      # Railway port binding (Railway reads this)
OPENCLAW_STATE_DIR=/data/.openclaw             # Persistent state directory
OPENCLAW_WORKSPACE_DIR=/data/workspace         # Persistent workspace directory
NODE_ENV=production                            # Production mode
```

Generate a secure gateway token: `openssl rand -hex 32`

**All of these must be set on every instance.** Missing `OPENCLAW_STATE_DIR` or `OPENCLAW_WORKSPACE_DIR` means state won't persist across redeploys even with the volume mounted.

**Each instance needs its own Telegram bot.** One bot token = one OpenClaw instance. Create a new bot with @BotFather for each instance.
