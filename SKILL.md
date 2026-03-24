---
name: openclaw-railway
description: Deploy OpenClaw instances to Railway with Venice AI as the default inference provider. Use when asked to deploy OpenClaw to Railway, create a cloud-hosted OpenClaw instance, set up OpenClaw on a PaaS platform, or spin up a new OpenClaw agent in the cloud. Also use when troubleshooting Railway OpenClaw deployments that fail to start, crash on boot, or show config/auth errors.
---

# OpenClaw Railway Deployment

Deploy OpenClaw to Railway as a containerized service with Venice AI inference.

## Prerequisites

- Railway CLI installed (`npm install -g @railway/cli`)
- Railway CLI authenticated (`railway login`)
- Venice AI API key (set as Railway env var, never in code)

## Deployment Workflow

### 1. Prepare deployment files

Create a working directory with three files. Use the templates in `references/deployment-files.md` for exact contents.

Required files:
- `Dockerfile` — node:22-slim, OpenClaw install, config copy, foreground gateway
- `config.json` — gateway mode, auth, Control UI flags, default model
- `railway.json` — Dockerfile builder, /data volume mount, restart policy

### 2. Create Railway project and set env vars

```bash
railway init
railway variables set VENICE_API_KEY=<user-provided-key>
railway variables set TELEGRAM_BOT_TOKEN=<user-provided-bot-token>
railway variables set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
railway variables set OPENCLAW_GATEWAY_PORT=8080
railway variables set PORT=8080
railway variables set OPENCLAW_STATE_DIR=/data/.openclaw
railway variables set OPENCLAW_WORKSPACE_DIR=/data/workspace
railway variables set NODE_ENV=production
railway variables set OPENCLAW_NON_INTERACTIVE=1
```

The Telegram bot token comes from @BotFather on Telegram (`/newbot`). This is a manual step — the user must create the bot and provide the token.

Record the generated gateway token — the user needs it to connect.

### 3. Deploy

```bash
railway up --detach
```

**Always use `railway up`**, never `railway redeploy`. Redeploy reuses the cached Docker image and ignores local file changes.

### 4. Generate public domain

```bash
railway domain
```

### 5. Verify

```bash
railway deployment list    # should show SUCCESS
railway logs               # should show "listening on ws://0.0.0.0:8080"
```

The Control UI is at `https://<domain>/openclaw`. Connect with the gateway token.

## Adding More Instances

```bash
railway add -s "openclaw-2"
railway service link openclaw-2
railway variables set VENICE_API_KEY=<key>
railway variables set TELEGRAM_BOT_TOKEN=<new-bot-token>
railway variables set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
railway variables set OPENCLAW_GATEWAY_PORT=8080
railway variables set PORT=8080
railway variables set OPENCLAW_STATE_DIR=/data/.openclaw
railway variables set OPENCLAW_WORKSPACE_DIR=/data/workspace
railway variables set NODE_ENV=production
railway variables set OPENCLAW_NON_INTERACTIVE=1
railway domain
railway up --detach
```

Each instance needs its own unique Telegram bot (one bot = one OpenClaw instance).

Each instance gets its own URL, token, and can connect to different channels.

## Critical Rules

1. **`gateway run` not `gateway start`** — `run` = foreground (Docker), `start` = systemd (bare metal)
2. **`--bind lan`** — required so gateway listens on 0.0.0.0, not localhost
3. **`--allow-unconfigured`** — lets gateway start without interactive setup wizard
4. **Config is JSON** — `openclaw.json`, not YAML. Set `OPENCLAW_CONFIG_PATH` env var to override location.
5. **`gateway.auth` is an object** — `{"mode": "token"}`, not the string `"token"`
6. **`VENICE_API_KEY` must be set before deploy** — otherwise Venice provider doesn't register its model catalog and you get "Unknown model" errors
7. **Never commit secrets** — API keys and tokens go in Railway env vars only

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| "Missing config" | No gateway mode configured | Add `--allow-unconfigured` to CMD |
| "non-loopback Control UI requires allowedOrigins" | Railway reverse proxy | Set `dangerouslyAllowHostHeaderOriginFallback: true` |
| "Pairing required" | Device auth enabled | Set `dangerouslyDisableDeviceAuth: true` |
| "gateway.auth: expected object" | Auth field wrong type | Use `{"mode": "token"}` object form |
| "Unknown model: venice/..." | No Venice API key | Set `VENICE_API_KEY` env var and redeploy |
| Changes not applying | `railway redeploy` caches old image | Use `railway up` instead |
| Container exits immediately | Using `gateway start` | Use `gateway run` |

## Changing the Default Model

Edit `config.json` → `agents.defaults.model.primary`. Venice models:

```
venice/claude-sonnet-4-6    venice/claude-opus-4-6
venice/claude-sonnet-4-5    venice/claude-opus-4-5
venice/llama-3.3-70b        venice/deepseek-r1-671b
```

Full list: `curl -s https://api.venice.ai/api/v1/models | jq '.data[].id'`

## Telegram Bot Setup

Telegram is pre-enabled in config.json. The user must:

1. **Create bot** — message @BotFather on Telegram → `/newbot` → copy the token
2. **Set env var** — `railway variables set TELEGRAM_BOT_TOKEN=<token>`
3. **Deploy/redeploy** — `railway up --detach`
4. **Pair** — message the bot on Telegram, get a pairing code, then:
   ```bash
   railway ssh
   openclaw pairing approve telegram <CODE>
   ```

To skip pairing (public bots), change `dmPolicy` from `"pairing"` to `"open"` in config.json.

## Reference Files

- `references/deployment-files.md` — Exact Dockerfile, config.json, and railway.json contents
