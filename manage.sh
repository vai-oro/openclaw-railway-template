#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTANCES=("openclaw-1" "openclaw-2" "openclaw-3" "openclaw-4")

show_help() {
    echo -e "${BLUE}OpenClaw Railway Management Script${NC}"
    echo "=================================="
    echo ""
    echo "Usage: ./manage.sh <command>"
    echo ""
    echo "Commands:"
    echo "  status     - Check status of all instances"
    echo "  logs       - View logs for all instances"
    echo "  restart    - Restart all instances"
    echo "  domains    - Show domains for all instances"
    echo "  env        - Show environment variables for an instance"
    echo "  update     - Update OpenClaw on all instances"
    echo "  destroy    - Destroy all instances (careful!)"
    echo "  help       - Show this help"
}

check_status() {
    echo -e "${BLUE}📊 Checking status of all OpenClaw instances...${NC}"
    echo ""
    
    for instance_name in "${INSTANCES[@]}"; do
        echo -e "${YELLOW}${instance_name}:${NC}"
        
        # Check Railway service status
        echo -n "  Railway Status: "
        if railway status --service ${instance_name} 2>/dev/null | grep -q "Active"; then
            echo -e "${GREEN}Active${NC}"
        else
            echo -e "${RED}Inactive${NC}"
        fi
        
        # Check OpenClaw health
        echo -n "  OpenClaw Health: "
        if railway run --service ${instance_name} -- openclaw gateway status --require-rpc --timeout 10000 2>/dev/null; then
            echo -e "${GREEN}Healthy${NC}"
        else
            echo -e "${RED}Unhealthy${NC}"
        fi
        
        echo ""
    done
}

view_logs() {
    echo -e "${BLUE}📋 Viewing logs for all instances...${NC}"
    echo "Press Ctrl+C to stop following logs"
    echo ""
    
    for instance_name in "${INSTANCES[@]}"; do
        echo -e "${YELLOW}=== ${instance_name} logs ===${NC}"
        railway logs --service ${instance_name} --num 50
        echo ""
    done
}

restart_all() {
    echo -e "${BLUE}🔄 Restarting all OpenClaw instances...${NC}"
    
    for instance_name in "${INSTANCES[@]}"; do
        echo -e "${YELLOW}Restarting ${instance_name}...${NC}"
        railway service restart --service ${instance_name}
        echo -e "${GREEN}✅ ${instance_name} restart initiated${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}⏳ Waiting for restarts to complete...${NC}"
    sleep 30
    
    # Health check after restart
    check_status
}

show_domains() {
    echo -e "${BLUE}🌐 Instance domains:${NC}"
    echo ""
    
    for instance_name in "${INSTANCES[@]}"; do
        echo -e "${YELLOW}${instance_name}:${NC}"
        domain=$(railway domain --service ${instance_name} 2>/dev/null || echo "No custom domain")
        echo "  ${domain}"
        echo ""
    done
}

show_env() {
    if [ -z "$1" ]; then
        echo -e "${RED}Please specify an instance: openclaw-1, openclaw-2, openclaw-3, or openclaw-4${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🔧 Environment variables for $1:${NC}"
    railway variables --service $1
}

update_all() {
    echo -e "${BLUE}⬆️  Updating OpenClaw on all instances...${NC}"
    
    for instance_name in "${INSTANCES[@]}"; do
        echo -e "${YELLOW}Updating ${instance_name}...${NC}"
        
        # Trigger redeploy to get latest OpenClaw
        railway redeploy --service ${instance_name}
        
        echo -e "${GREEN}✅ ${instance_name} update initiated${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}⏳ Waiting for updates to complete...${NC}"
    sleep 60
    
    # Health check after update
    check_status
}

destroy_all() {
    echo -e "${RED}⚠️  WARNING: This will destroy all OpenClaw instances!${NC}"
    read -p "Type 'DELETE' to confirm: " confirmation
    
    if [ "$confirmation" != "DELETE" ]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi
    
    echo -e "${RED}🗑️  Destroying all instances...${NC}"
    
    for instance_name in "${INSTANCES[@]}"; do
        echo -e "${YELLOW}Destroying ${instance_name}...${NC}"
        railway service delete ${instance_name} --yes || echo "Service may not exist"
    done
    
    echo -e "${GREEN}✅ All instances destroyed.${NC}"
}

# Main script
case "$1" in
    status)
        check_status
        ;;
    logs)
        view_logs
        ;;
    restart)
        restart_all
        ;;
    domains)
        show_domains
        ;;
    env)
        show_env $2
        ;;
    update)
        update_all
        ;;
    destroy)
        destroy_all
        ;;
    help|*)
        show_help
        ;;
esac