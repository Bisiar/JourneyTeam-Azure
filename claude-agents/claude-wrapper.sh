#!/bin/bash

# Claude Code Wrapper - Automatically starts agents with Claude
# This script replaces the 'claude' command to ensure agents are always running

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(dirname "$SCRIPT_DIR")/claude-agents"
DAEMON_SCRIPT="$AGENTS_DIR/daemon/claude-daemon.sh"
PID_FILE=".claude/daemon.pid"
CLAUDE_ORIGINAL=$(which claude)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Check if daemon is running
is_daemon_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Start daemon if not running
ensure_daemon_running() {
    if ! is_daemon_running; then
        echo -e "${YELLOW}🚀 Starting Claude Agents Daemon...${NC}"
        
        # Check if we're in a git repository
        if [ -d ".git" ]; then
            # Start daemon in background
            "$DAEMON_SCRIPT" start > /dev/null 2>&1 &
            
            # Wait for daemon to start
            local count=0
            while [ $count -lt 10 ]; do
                if is_daemon_running; then
                    echo -e "${GREEN}✅ Agents ready!${NC}"
                    echo -e "${BLUE}ℹ️  Monitoring: Architecture, Azure Naming, Documentation, Audit${NC}"
                    return 0
                fi
                sleep 0.5
                count=$((count + 1))
            done
            
            echo -e "${YELLOW}⚠️  Daemon starting slowly, continuing anyway...${NC}"
        else
            echo -e "${YELLOW}ℹ️  Not in a git repository, agents not started${NC}"
        fi
    else
        echo -e "${GREEN}✅ Agents already running${NC}"
    fi
}

# Show agent status
show_agent_status() {
    if is_daemon_running && [ -f ".claude/daemon.status" ]; then
        local status=$(cat .claude/daemon.status 2>/dev/null | grep -o '"status": "[^"]*"' | cut -d'"' -f4)
        local doc_status=$(cat .claude/daemon.status | grep -o '"documentation": "[^"]*"' | cut -d'"' -f4)
        local arch_status=$(cat .claude/daemon.status | grep -o '"architecture": "[^"]*"' | cut -d'"' -f4)
        local azure_status=$(cat .claude/daemon.status | grep -o '"azure": "[^"]*"' | cut -d'"' -f4)
        local audit_status=$(cat .claude/daemon.status | grep -o '"audit": "[^"]*"' | cut -d'"' -f4)
        
        echo -e "${BLUE}Agent Status:${NC} 📚 Doc:$doc_status 🏛️ Arch:$arch_status ☁️ Azure:$azure_status ✅ Audit:$audit_status"
    fi
}

# Inject agent awareness into Claude prompts
inject_agent_context() {
    local original_prompt="$1"
    local enhanced_prompt="$original_prompt"
    
    # Check what type of task this might be
    if [[ "$original_prompt" == *"bicep"* ]] || [[ "$original_prompt" == *"infrastructure"* ]] || [[ "$original_prompt" == *"azure"* ]]; then
        enhanced_prompt="[Azure Infrastructure Agent Active - enforcing naming conventions] $original_prompt"
    elif [[ "$original_prompt" == *"architecture"* ]] || [[ "$original_prompt" == *"onion"* ]] || [[ "$original_prompt" == *"layer"* ]]; then
        enhanced_prompt="[Architecture Enforcement Agent Active - validating onion architecture] $original_prompt"
    elif [[ "$original_prompt" == *"document"* ]] || [[ "$original_prompt" == *"readme"* ]]; then
        enhanced_prompt="[WAF Documentation Agent Active - maintaining documentation] $original_prompt"
    elif [[ "$original_prompt" == *"audit"* ]] || [[ "$original_prompt" == *"compliance"* ]]; then
        enhanced_prompt="[Audit Orchestration Agent Active - checking compliance] $original_prompt"
    fi
    
    # Add general context about active agents
    if [ "$enhanced_prompt" != "$original_prompt" ] || [[ "$original_prompt" == *"scaffold"* ]] || [[ "$original_prompt" == *"create"* ]]; then
        enhanced_prompt="$enhanced_prompt

ACTIVE AGENTS: Architecture Enforcement (onion), Azure Naming (rg-{name}-{env}), WAF Documentation, Audit Orchestration
NAMING: Use project name 'reflections' not resourceToken for Azure resources
ARCHITECTURE: ViewModels in Shared/, no DB in Domain"
    fi
    
    echo "$enhanced_prompt"
}

# Main execution
main() {
    # Special commands
    case "${1:-}" in
        agents)
            # Show agent management commands
            echo -e "${BLUE}Claude Agents Management:${NC}"
            echo "  claude agents status    - Show agent status"
            echo "  claude agents start     - Start agents daemon"
            echo "  claude agents stop      - Stop agents daemon"
            echo "  claude agents restart   - Restart agents daemon"
            echo "  claude agents logs      - View agent logs"
            echo "  claude agents monitor   - Open monitoring UI"
            exit 0
            ;;
        agents:status)
            show_agent_status
            exit 0
            ;;
        agents:start)
            "$DAEMON_SCRIPT" start
            exit 0
            ;;
        agents:stop)
            "$DAEMON_SCRIPT" stop
            exit 0
            ;;
        agents:restart)
            "$DAEMON_SCRIPT" stop 2>/dev/null || true
            sleep 1
            "$DAEMON_SCRIPT" start
            exit 0
            ;;
        agents:logs)
            tail -f .claude/daemon.log
            exit 0
            ;;
        agents:monitor)
            "$AGENTS_DIR/daemon/claude-monitor.sh"
            exit 0
            ;;
    esac
    
    # Ensure daemon is running before Claude command
    ensure_daemon_running
    
    # Check if we have a prompt that needs agent context
    if [ $# -gt 0 ] && [ "${1:0:1}" != "-" ]; then
        # First argument is likely a prompt, enhance it
        enhanced_prompt=$(inject_agent_context "$1")
        shift
        
        # Run Claude with enhanced prompt
        "$CLAUDE_ORIGINAL" "$enhanced_prompt" "$@"
    else
        # Run Claude normally (no prompt to enhance)
        "$CLAUDE_ORIGINAL" "$@"
    fi
    
    # Show agent status after command
    show_agent_status
}

# Install wrapper
install_wrapper() {
    echo -e "${BLUE}Installing Claude wrapper...${NC}"
    
    # Create alias in shell profile
    local shell_profile=""
    if [ -f ~/.zshrc ]; then
        shell_profile=~/.zshrc
    elif [ -f ~/.bashrc ]; then
        shell_profile=~/.bashrc
    fi
    
    if [ -n "$shell_profile" ]; then
        # Remove old alias if exists
        sed -i '' '/alias claude=/d' "$shell_profile" 2>/dev/null || sed -i '/alias claude=/d' "$shell_profile"
        
        # Add new alias
        echo "alias claude='$SCRIPT_DIR/claude-wrapper.sh'" >> "$shell_profile"
        echo -e "${GREEN}✅ Wrapper installed! Restart your terminal or run: source $shell_profile${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not find shell profile. Add this alias manually:${NC}"
        echo "alias claude='$SCRIPT_DIR/claude-wrapper.sh'"
    fi
}

# Check if this is an installation request
if [ "${1:-}" = "--install" ]; then
    install_wrapper
    exit 0
fi

main "$@"