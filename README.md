# OpenClaw Railway Multi-Instance Template

Deploy 4 OpenClaw instances to Railway with a single command — no dashboard required!

## 🚀 Quick Deploy

```bash
# 1. Clone and deploy
git clone <your-repo-url>
cd openclaw-railway-template
chmod +x *.sh

# 2. Install Railway CLI (if needed)
npm install -g @railway/cli

# 3. Deploy all 4 instances
./deploy.sh

# 4. Configure with your API keys
./config-template.sh
```

**That's it!** 4 OpenClaw instances running on Railway in ~5 minutes.

## 📁 What's Included

- **`Dockerfile`** — OpenClaw container configuration
- **`railway.json`** — Railway deployment settings
- **`deploy.sh`** — Deploy 4 instances with one command
- **`config-template.sh`** — Set API keys for all instances
- **`manage.sh`** — Manage all instances (status, logs, restart, etc.)

## 🛠️ Management Commands

```bash
./manage.sh status     # Check all instance health
./manage.sh logs       # View logs for all instances
./manage.sh restart    # Restart all instances
./manage.sh domains    # Show instance URLs
./manage.sh env openclaw-1  # Show environment variables
./manage.sh update     # Update OpenClaw on all instances
./manage.sh destroy    # Destroy all instances (careful!)
```

## ⚙️ Configuration

Each instance gets:
- **Unique gateway token** (auto-generated)
- **Separate Telegram bot** (you provide tokens)
- **Shared Anthropic API key** (cost optimization)
- **Health checks** and **auto-restart**

## 🔧 Manual Railway Commands

If you prefer manual control:

```bash
# Login
railway login

# Deploy to specific instance
railway up --service openclaw-1

# Set environment variables
railway variables set --service openclaw-1 ANTHROPIC_API_KEY=sk-...

# View logs
railway logs --service openclaw-1 --follow

# Get instance URL
railway domain --service openclaw-1

# Restart instance
railway service restart --service openclaw-1
```

## 🏥 Health Monitoring

Each instance has built-in health checks:
- **Railway health check** — HTTP endpoint at `/health`
- **OpenClaw RPC check** — `openclaw gateway status --require-rpc`
- **Auto-restart** on failure (up to 3 retries)

## 🔐 Environment Variables

Required for each instance:
```bash
ANTHROPIC_API_KEY=sk-...           # Your Anthropic API key
TELEGRAM_BOT_TOKEN=123:ABC...      # Telegram bot token (unique per instance)
OPENCLAW_GATEWAY_TOKEN=random...   # Auto-generated security token
OPENCLAW_NON_INTERACTIVE=1         # Non-interactive mode
PORT=8080                          # Container port
NODE_ENV=production                # Production mode
```

## 📊 Instance Architecture

```
Railway Project: openclaw-deployment
├── openclaw-1 (Telegram Bot 1)
├── openclaw-2 (Telegram Bot 2) 
├── openclaw-3 (Telegram Bot 3)
└── openclaw-4 (Telegram Bot 4)
```

Each instance:
- Runs independently
- Has its own URL
- Uses shared Anthropic credits
- Connects to different Telegram bots

## 🚨 Troubleshooting

**Instance won't start?**
```bash
./manage.sh logs  # Check logs for errors
railway variables --service openclaw-1  # Verify environment variables
```

**Health check failing?**
```bash
railway run --service openclaw-1 -- openclaw gateway status --require-rpc
```

**Need to reset everything?**
```bash
./manage.sh destroy  # Nuclear option - destroys all instances
./deploy.sh          # Redeploy from scratch
```

## 💡 Pro Tips

1. **Cost optimization**: All instances share the same Anthropic API key
2. **Load balancing**: Use different Telegram bots for different user groups
3. **Monitoring**: Set up Railway notifications for health check failures
4. **Scaling**: Easy to add more instances by editing the `INSTANCES` array
5. **Updates**: Use `./manage.sh update` to update OpenClaw across all instances

## 📝 Customization

Edit these files to customize your deployment:
- **`deploy.sh`** — Change instance names or count
- **`Dockerfile`** — Modify OpenClaw configuration  
- **`railway.json`** — Adjust Railway deployment settings
- **`manage.sh`** — Add custom management commands

## 🔗 Useful Links

- [Railway Documentation](https://docs.railway.app)
- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Railway CLI Reference](https://docs.railway.app/reference/cli-api)