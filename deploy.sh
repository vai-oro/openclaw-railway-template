#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTANCES=("openclaw-1" "openclaw-2" "openclaw-3" "openclaw-4")
PROJECT_NAME="openclaw-deployment"

echo -e "${BLUE}🚀 OpenClaw Railway Multi-Instance Deployment${NC}"
echo "=================================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI not found. Installing...${NC}"
    npm install -g @railway/cli
fi

# Login check
echo -e "${YELLOW}🔐 Checking Railway authentication...${NC}"
if ! railway auth &> /dev/null; then
    echo -e "${YELLOW}Please login to Railway:${NC}"
    railway login
fi

# Create project
echo -e "${BLUE}📁 Creating Railway project: ${PROJECT_NAME}${NC}"
railway login
railway new ${PROJECT_NAME} --template empty

# Deploy each instance
for i in "${!INSTANCES[@]}"; do
    instance_name="${INSTANCES[$i]}"
    instance_num=$((i + 1))
    
    echo ""
    echo -e "${BLUE}🚀 Deploying instance ${instance_num}/4: ${instance_name}${NC}"
    echo "----------------------------------------"
    
    # Create service
    echo -e "${YELLOW}Creating service: ${instance_name}${NC}"
    railway service create ${instance_name}
    
    # Set environment variables
    echo -e "${YELLOW}Setting environment variables...${NC}"
    railway variables set \
        --service ${instance_name} \
        OPENCLAW_GATEWAY_TOKEN="gateway-token-${instance_num}-$(openssl rand -hex 16)" \
        OPENCLAW_NON_INTERACTIVE="1" \
        PORT="8080" \
        NODE_ENV="production"
    
    # Deploy to this service
    echo -e "${YELLOW}Deploying to ${instance_name}...${NC}"
    railway up --service ${instance_name}
    
    # Wait for deployment
    echo -e "${YELLOW}⏳ Waiting for ${instance_name} to become healthy...${NC}"
    sleep 30
    
    # Health check
    echo -e "${YELLOW}🏥 Health checking ${instance_name}...${NC}"
    if railway run --service ${instance_name} -- openclaw gateway status --require-rpc --timeout 15000; then
        echo -e "${GREEN}✅ ${instance_name} is healthy!${NC}"
    else
        echo -e "${RED}❌ ${instance_name} failed health check${NC}"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}🎉 All 4 OpenClaw instances deployed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "======================"

# Get service info
for instance_name in "${INSTANCES[@]}"; do
    echo -e "${YELLOW}${instance_name}:${NC}"
    railway domain --service ${instance_name} 2>/dev/null || echo "  No custom domain set"
    echo "  Status: $(railway status --service ${instance_name} 2>/dev/null || echo 'Unknown')"
    echo ""
done

echo -e "${BLUE}💡 Next Steps:${NC}"
echo "• Set your provider API keys: railway variables set --service openclaw-1 ANTHROPIC_API_KEY=sk-..."
echo "• Set Telegram bot tokens: railway variables set --service openclaw-1 TELEGRAM_BOT_TOKEN=123:ABC..."
echo "• View logs: railway logs --service openclaw-1"
echo "• Get service URLs: railway domain --service openclaw-1"