# OpenClaw on Railway — Deployment Template

Deploy OpenClaw to Railway with Venice AI as the default inference provider.

## What You Need

- [Railway CLI](https://docs.railway.app/reference/cli-api) (`npm install -g @railway/cli`)
- A Venice AI API key ([venice.ai](https://venice.ai))
- A Railway account

## Deploy in 5 Minutes

### 1. Create a Railway project

```bash
railway login
railway init    # creates a new project
```

### 2. Set environment variables

```bash
# Required
railway variables set VENICE_API_KEY=your-venice-api-key-here
railway variables set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
railway variables set OPENCLAW_GATEWAY_PORT=8080

# Recommended
railway variables set NODE_ENV=production
railway variables set OPENCLAW_NON_INTERACTIVE=1
```

### 3. Deploy

```bash
railway up --detach
```

### 4. Connect

Open the Control UI at:
```
https://<your-railway-domain>/openclaw
```

Enter your gateway token to connect. No pairing needed — token auth only.

## How It Works

**Dockerfile** installs OpenClaw, copies `config.json` as the gateway config, and starts the gateway in foreground mode.

**config.json** pre-configures:
- `venice/claude-sonnet-4-6` as the default model
- Token-only auth (no device pairing)
- Host-header origin fallback for Railway's reverse proxy
- Local gateway mode with `--allow-unconfigured` for first boot

**Railway provides:**
- Persistent volume at `/data` for state across redeploys
- Public HTTPS domain
- Auto-restart on failure

## Configuration

### Change the default model

Edit `config.json` → `agents.defaults.model.primary`:

```json
"model": {
  "primary": "venice/claude-sonnet-4-6"
}
```

Venice models available: `claude-sonnet-4-6`, `claude-opus-4-6`, `claude-sonnet-4-5`, `claude-opus-4-5`, `llama-3.3-70b`, `deepseek-r1-671b`, and more.

### Add a Telegram bot

Set the bot token as an env var on Railway:
```bash
railway variables set TELEGRAM_BOT_TOKEN=123456:ABC-your-bot-token
```

Then configure via the Control UI or update `config.json`.

### Add more providers

Set API keys as Railway environment variables:
```bash
railway variables set ANTHROPIC_API_KEY=sk-ant-...
railway variables set OPENAI_API_KEY=sk-...
```

OpenClaw auto-detects provider keys from the environment.

## Common Issues We Hit (So You Don't Have To)

| Problem | Cause | Fix |
|---------|-------|-----|
| "Missing config" on startup | No config file or gateway mode | Use `--allow-unconfigured` flag in CMD |
| "non-loopback Control UI requires allowedOrigins" | Railway is a reverse proxy | Set `dangerouslyAllowHostHeaderOriginFallback: true` |
| "Pairing required" in Control UI | Device auth enabled by default | Set `dangerouslyDisableDeviceAuth: true` |
| `gateway.auth: expected object` | Auth must be `{"mode": "token"}`, not `"token"` | Use the object form |
| Config not loading | OpenClaw uses JSON (`openclaw.json`), not YAML | Set `OPENCLAW_CONFIG_PATH` pointing to `.json` file |
| `railway redeploy` uses old code | Redeploy reuses cached image | Use `railway up` to push new code |
| Container exits immediately | Using `gateway start` (systemd) | Use `gateway run` (foreground, correct for Docker) |
| Port not binding | Railway needs explicit port | Set `OPENCLAW_GATEWAY_PORT=8080` env var |

## Updating OpenClaw

Rebuild and redeploy to get the latest version:

```bash
railway up --detach
```

The Dockerfile uses `openclaw@latest`, so each build pulls the newest release.

## File Structure

```
├── Dockerfile          # Container setup + OpenClaw install
├── config.json         # Gateway config (model, auth, UI settings)
├── railway.json        # Railway platform config (volumes, restart policy)
└── README.md           # This file
```

## Security Notes

This template uses two "dangerous" flags for Railway compatibility:
- `dangerouslyAllowHostHeaderOriginFallback` — needed because Railway terminates TLS at their proxy
- `dangerouslyDisableDeviceAuth` — needed because there's no terminal to approve device pairing

Both are acceptable for Railway deployments. The gateway token provides authentication. For production, consider setting explicit `allowedOrigins` instead of the host-header fallback.

## Links

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Venice AI](https://venice.ai)
- [Railway Docs](https://docs.railway.app)
