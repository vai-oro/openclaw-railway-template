# OpenClaw on Railway — Deployment Template

Deploy OpenClaw to Railway with Venice AI as the default inference provider.

**Battle-tested** — this template was built through iterative debugging of a real Railway deployment. Every config choice and troubleshooting entry comes from an actual failure we encountered and resolved.

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
# Required — set ALL of these on every instance
railway variables set VENICE_API_KEY=your-venice-api-key-here
railway variables set TELEGRAM_BOT_TOKEN=your-telegram-bot-token-here
railway variables set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
railway variables set OPENCLAW_GATEWAY_PORT=8080
railway variables set PORT=8080
railway variables set OPENCLAW_STATE_DIR=/data/.openclaw
railway variables set OPENCLAW_WORKSPACE_DIR=/data/workspace
railway variables set NODE_ENV=production
```

> **Need a Telegram bot token?** See [Setting Up a Telegram Bot](#setting-up-a-telegram-bot) below.

> **Important:** Note the gateway token value — you'll need it to connect to the Control UI. Run `railway variables` to retrieve it later.

### 3. Deploy

```bash
railway up --detach
```

> **Always use `railway up`**, not `railway redeploy`. The `redeploy` command reuses the cached Docker image and won't pick up any local file changes. `railway up` uploads your current code and triggers a fresh build every time.

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
- Token-only auth (no device pairing required)
- Host-header origin fallback for Railway's reverse proxy
- Local gateway mode with `--allow-unconfigured` for first boot

**Railway provides:**
- Persistent volume at `/data` for state across redeploys
- Public HTTPS domain with TLS termination
- Auto-restart on failure (up to 3 retries)

## Configuration

### Change the default model

Edit `config.json` → `agents.defaults.model.primary`:

```json
"model": {
  "primary": "venice/claude-sonnet-4-6"
}
```

Venice models available: `claude-sonnet-4-6`, `claude-opus-4-6`, `claude-sonnet-4-5`, `claude-opus-4-5`, `llama-3.3-70b`, `deepseek-r1-671b`, and more.

Full list: `curl -s https://api.venice.ai/api/v1/models | jq '.data[].id'`

### Setting Up a Telegram Bot

Telegram is pre-configured in `config.json` — you just need to create a bot and set the token.

#### Step 1: Create a bot with BotFather

1. Open Telegram and search for **@BotFather** (verify the blue checkmark)
2. Send `/newbot`
3. Choose a **display name** (e.g., "My OpenClaw Agent")
4. Choose a **username** — must end in `bot` (e.g., `my_openclaw_bot`)
5. BotFather replies with your bot token — looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
6. Copy the token

#### Step 2: Set the token on Railway

```bash
railway variables set TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
```

The gateway picks up `TELEGRAM_BOT_TOKEN` automatically — no config file changes needed.

#### Step 3: Pair your Telegram account

After deploying, message your bot on Telegram. It will respond with a **pairing code**. Approve it by SSH-ing into the Railway container:

```bash
railway ssh
openclaw pairing approve telegram <CODE>
```

This is a one-time step. Once paired, your Telegram account is trusted for future messages.

> **Tip:** If you want the bot to accept messages from anyone without pairing, change `dmPolicy` in `config.json` from `"pairing"` to `"open"`. Only do this for public-facing bots.

#### Optional: Configure group behavior

To add the bot to a Telegram group:
1. Add the bot to your group in Telegram
2. The bot defaults to requiring @mention in groups (`requireMention: true`)
3. Disable Privacy Mode in BotFather (`/setprivacy` → Disable) if you want the bot to see all group messages

### Use a different provider

Venice is the default, but OpenClaw supports all major providers. Set the API key as a Railway env var and update the model in `config.json`:

```bash
# Optional — set any providers you want to use
railway variables set ANTHROPIC_API_KEY=your-anthropic-key
railway variables set OPENAI_API_KEY=your-openai-key
railway variables set GOOGLE_GENERATIVE_AI_API_KEY=your-google-key
railway variables set GROQ_API_KEY=your-groq-key
railway variables set MISTRAL_API_KEY=your-mistral-key
railway variables set OPENROUTER_API_KEY=your-openrouter-key
railway variables set XAI_API_KEY=your-xai-key
```

Then change the model in `config.json`:
```json
"model": {
  "primary": "anthropic/claude-sonnet-4-6"
}
```

OpenClaw auto-detects provider keys from the environment — just set the key and reference the model.

## Best Practices

### Docker & OpenClaw

- **Always use `openclaw gateway run`** for containers — this runs the gateway as a foreground process. `openclaw gateway start` is for systemd and will fail in Docker.
- **Use `--bind lan`** so the gateway listens on `0.0.0.0` instead of localhost. Railway routes external traffic to your container's port, which requires non-loopback binding.
- **Use `--allow-unconfigured`** for first boot. Without this, OpenClaw requires a complete interactive setup before starting. This flag lets it start with a minimal config so you can configure via the Control UI afterward.
- **Config is JSON, not YAML.** OpenClaw's config file is `openclaw.json`. If you use `OPENCLAW_CONFIG_PATH`, point it to a `.json` file.
- **Set `OPENCLAW_GATEWAY_PORT=8080`** as an env var. Railway expects apps to bind to a specific port and this tells OpenClaw which port to use.

### Railway Platform

- **`railway up` for code changes, always.** `railway redeploy` only restarts the existing cached image — it does NOT pick up local file changes.
- **Use persistent volumes** for `/data`. Without this, all config and state is lost on every redeploy.
- **Check logs with `railway logs --deployment <id>`** — you can pull crash logs remotely without needing the Railway dashboard.
- **List deployments with `railway deployment list`** to check status (SUCCESS/CRASHED/REMOVED).

### Security

- **Never commit secrets to the repo.** API keys and gateway tokens go in Railway environment variables only.
- **Generate unique gateway tokens** with `openssl rand -hex 32`. Don't reuse tokens across instances.
- **The two "dangerous" flags are necessary for Railway** but should be understood:
  - `dangerouslyAllowHostHeaderOriginFallback` — Railway terminates TLS at their reverse proxy, so the browser's Origin header doesn't match what OpenClaw expects. This flag tells OpenClaw to trust the Host header instead. For production, set explicit `allowedOrigins` with your Railway domain.
  - `dangerouslyDisableDeviceAuth` — OpenClaw has a device pairing layer where new browsers must be approved from the server terminal. Since Railway is headless (no SSH by default), we disable this and rely on token auth only.

### Auth Configuration

- **`gateway.auth` must be an object**, not a string. Correct: `{"mode": "token"}`. Wrong: `"token"`.
- **`auth.mode: "token"`** means the gateway token is the only auth check. No device pairing, no passwords.

## Troubleshooting

### Quick Reference

| Problem | Cause | Fix |
|---------|-------|-----|
| "Missing config" on startup | No config file or gateway mode | Use `--allow-unconfigured` flag in CMD |
| "non-loopback Control UI requires allowedOrigins" | Railway's reverse proxy | Set `dangerouslyAllowHostHeaderOriginFallback: true` |
| "Pairing required" in Control UI | Device auth enabled by default | Set `dangerouslyDisableDeviceAuth: true` |
| `gateway.auth: expected object, received string` | Auth config must be an object | Use `{"mode": "token"}` not `"token"` |
| Config file not loading | Wrong file format or path | OpenClaw uses JSON; set `OPENCLAW_CONFIG_PATH` to a `.json` file |
| `railway redeploy` doesn't apply changes | Redeploy reuses cached image | Use `railway up` to push and rebuild |
| Container exits immediately | Using `gateway start` (systemd) | Use `gateway run` (foreground process) |
| Port not binding / health check fails | Railway can't reach the app | Set `OPENCLAW_GATEWAY_PORT=8080` env var |
| "Config invalid" crash loop | Bad config schema | Check exact field types — run `openclaw doctor --fix` via `railway ssh` |

### Detailed Walkthrough

If your deployment isn't working, here's the exact sequence of issues we encountered and solved, in order:

**1. Container exits with "Missing config"**

OpenClaw expects an interactive setup wizard on first run. In Docker, pass `--allow-unconfigured` in the CMD to skip this. The gateway starts with minimal defaults and you configure via the Control UI.

**2. Container exits with "non-loopback Control UI requires allowedOrigins"**

When binding to `0.0.0.0` (required for Railway), OpenClaw's Control UI enforces an origin allowlist. Railway terminates TLS at their proxy, so the origin doesn't match. Set `dangerouslyAllowHostHeaderOriginFallback: true` in `config.json` under `gateway.controlUi`.

**3. Control UI loads but says "Pairing required"**

OpenClaw has a device-level trust layer on top of token auth. New browsers must be "paired" — approved from the server terminal. Since Railway is headless, set `dangerouslyDisableDeviceAuth: true` to skip this and rely on token auth only.

**4. Config crashes with "gateway.auth: expected object, received string"**

Setting `"auth": "token"` is wrong. The correct format is:
```json
"auth": {
  "mode": "token"
}
```

**5. Changes not applying after redeploy**

`railway redeploy` reuses the cached Docker image. If you changed files locally (Dockerfile, config.json, etc.), you must use `railway up` to upload and rebuild.

### Checking Logs

```bash
# List recent deployments and their status
railway deployment list

# View logs for a specific deployment
railway logs --deployment <deployment-id>

# SSH into a running container (if needed)
railway ssh
```

## Updating OpenClaw

Rebuild and redeploy to get the latest version:

```bash
railway up --detach
```

The Dockerfile uses `openclaw@latest`, so each build pulls the newest release.

## Spinning Up Additional Instances

To deploy a second OpenClaw instance in the same Railway project:

```bash
# Create a new service
railway add -s "openclaw-2"

# Link to it
railway service link openclaw-2

# Set ALL env vars (new unique token + new bot token per instance)
railway variables set VENICE_API_KEY=your-key
railway variables set TELEGRAM_BOT_TOKEN=your-new-bot-token
railway variables set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
railway variables set OPENCLAW_GATEWAY_PORT=8080
railway variables set PORT=8080
railway variables set OPENCLAW_STATE_DIR=/data/.openclaw
railway variables set OPENCLAW_WORKSPACE_DIR=/data/workspace
railway variables set NODE_ENV=production

# Generate domain and deploy
railway domain
railway up --detach
```

Each instance gets its own URL, token, and can connect to different chat channels.

## File Structure

```
├── Dockerfile          # Container: node:22-slim + OpenClaw install + config copy
├── config.json         # Gateway config: Venice model, token auth, Railway flags
├── railway.json        # Railway config: Dockerfile builder, /data volume, restart policy
└── README.md           # This file
```

## Links

- [OpenClaw Docs](https://docs.openclaw.ai)
- [OpenClaw Docker Guide](https://docs.openclaw.ai/install/docker)
- [OpenClaw Railway Guide](https://docs.openclaw.ai/install/railway)
- [Venice AI](https://venice.ai)
- [Venice API Models](https://api.venice.ai/api/v1/models)
- [Railway Docs](https://docs.railway.app)
- [Railway CLI Reference](https://docs.railway.app/reference/cli-api)
