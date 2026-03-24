#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTANCES=("openclaw-1" "openclaw-2" "openclaw-3" "openclaw-4")

echo -e "${BLUE}⚙️  OpenClaw Railway Configuration Setup${NC}"
echo "=========================================="

# Prompt for API keys
read -p "🔑 Enter your Anthropic API key: " ANTHROPIC_API_KEY
read -p "🤖 Enter your Telegram Bot Token (instance 1): " TELEGRAM_BOT_TOKEN_1
read -p "🤖 Enter your Telegram Bot Token (instance 2): " TELEGRAM_BOT_TOKEN_2
read -p "🤖 Enter your Telegram Bot Token (instance 3): " TELEGRAM_BOT_TOKEN_3  
read -p "🤖 Enter your Telegram Bot Token (instance 4): " TELEGRAM_BOT_TOKEN_4

TELEGRAM_TOKENS=("$TELEGRAM_BOT_TOKEN_1" "$TELEGRAM_BOT_TOKEN_2" "$TELEGRAM_BOT_TOKEN_3" "$TELEGRAM_BOT_TOKEN_4")

# Configure each instance
for i in "${!INSTANCES[@]}"; do
    instance_name="${INSTANCES[$i]}"
    telegram_token="${TELEGRAM_TOKENS[$i]}"
    instance_num=$((i + 1))
    
    echo ""
    echo -e "${BLUE}⚙️  Configuring ${instance_name}...${NC}"
    
    # Set all environment variables for this instance
    railway variables set \
        --service ${instance_name} \
        ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
        TELEGRAM_BOT_TOKEN="${telegram_token}" \
        OPENCLAW_GATEWAY_TOKEN="gateway-token-${instance_num}-$(openssl rand -hex 16)" \
        OPENCLAW_NON_INTERACTIVE="1" \
        PORT="8080" \
        NODE_ENV="production"
    
    echo -e "${GREEN}✅ ${instance_name} configured${NC}"
    
    # Restart the service to apply new config
    echo -e "${YELLOW}🔄 Restarting ${instance_name}...${NC}"
    railway service restart --service ${instance_name}
done

echo ""
echo -e "${GREEN}🎉 All instances configured and restarted!${NC}"
echo ""
echo -e "${BLUE}🏥 Health checking all instances...${NC}"

# Wait for restarts and health check
sleep 45

for instance_name in "${INSTANCES[@]}"; do
    echo -e "${YELLOW}Checking ${instance_name}...${NC}"
    if railway run --service ${instance_name} -- openclaw gateway status --require-rpc --timeout 15000; then
        echo -e "${GREEN}✅ ${instance_name} is healthy${NC}"
    else
        echo -e "${RED}❌ ${instance_name} failed health check${NC}"
    fi
done

echo ""
echo -e "${GREEN}🚀 Configuration complete!${NC}"