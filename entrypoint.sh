#!/bin/sh
# Startup entrypoint for Railway deployments.
# Restores the config from the image template if the volume config has auth.mode=none
# (which is incompatible with --bind lan and causes startup failures).

CONFIG_FILE="${OPENCLAW_CONFIG_PATH:-/data/.openclaw/openclaw.json}"
TEMPLATE_FILE="/app/openclaw.json.template"

if [ -f "$CONFIG_FILE" ] && [ -f "$TEMPLATE_FILE" ]; then
  # Check if the volume config has auth.mode=none (invalid for lan binding)
  AUTH_MODE=$(node -e "
    try {
      const c = JSON.parse(require('fs').readFileSync('$CONFIG_FILE', 'utf8'));
      process.stdout.write(c?.gateway?.auth?.mode || 'token');
    } catch(e) {
      process.stdout.write('invalid');
    }
  " 2>/dev/null)
  
  if [ "$AUTH_MODE" = "none" ] || [ "$AUTH_MODE" = "invalid" ]; then
    echo "[entrypoint] Config has auth.mode='$AUTH_MODE' (incompatible with lan binding). Restoring from template..."
    cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    echo "[entrypoint] Config restored."
  else
    echo "[entrypoint] Config OK (auth.mode=$AUTH_MODE)."
  fi
elif [ ! -f "$CONFIG_FILE" ] && [ -f "$TEMPLATE_FILE" ]; then
  echo "[entrypoint] Config missing, copying from template..."
  cp "$TEMPLATE_FILE" "$CONFIG_FILE"
fi

exec openclaw gateway run --bind lan
