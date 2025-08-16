#!/bin/bash

# Claude Agents Monitor - Terminal UI for daemon monitoring
# Shows real-time status and events from the daemon

set -e

# Configuration
REFRESH_RATE=1  # seconds
STATUS_FILE=".claude/daemon.status"
EVENTS_FILE=".claude/daemon.events"
PID_FILE=".claude/daemon.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# Terminal setup
setup_terminal() {
    # Save cursor position and clear screen
    tput smcup
    clear
    
    # Hide cursor
    tput civis
    
    # Set up signal handlers
    trap cleanup EXIT INT TERM
}

# Cleanup on exit
cleanup() {
    # Show cursor
    tput cnorm
    
    # Restore terminal
    tput rmcup
    
    echo -e "${GREEN}Monitor stopped${NC}"
    exit 0
}

# Draw header
draw_header() {
    local width=$(tput cols)
    local title="Claude Agents Monitor"
    local padding=$(( (width - ${#title}) / 2 ))
    
    tput cup 0 0
    echo -ne "${BLUE}${BOLD}"
    printf '%*s' "$width" | tr ' ' '═'
    echo -e "${NC}"
    
    tput cup 1 0
    printf '%*s' "$padding" ""
    echo -ne "${WHITE}${BOLD}$title${NC}"
    
    tput cup 2 0
    echo -ne "${BLUE}${BOLD}"
    printf '%*s' "$width" | tr ' ' '═'
    echo -e "${NC}"
}

# Draw agent status boxes
draw_agent_status() {
    local row=4
    local col=2
    local box_width=28
    
    # Read status if available
    local doc_status="idle"
    local arch_status="idle"
    local azure_status="idle"
    local audit_status="idle"
    
    if [ -f "$STATUS_FILE" ]; then
        local status_json=$(cat "$STATUS_FILE" 2>/dev/null || echo "{}")
        doc_status=$(echo "$status_json" | grep -o '"documentation": "[^"]*"' | cut -d'"' -f4 || echo "idle")
        arch_status=$(echo "$status_json" | grep -o '"architecture": "[^"]*"' | cut -d'"' -f4 || echo "idle")
        azure_status=$(echo "$status_json" | grep -o '"azure": "[^"]*"' | cut -d'"' -f4 || echo "idle")
        audit_status=$(echo "$status_json" | grep -o '"audit": "[^"]*"' | cut -d'"' -f4 || echo "idle")
    fi
    
    # Documentation Agent
    draw_agent_box $row $col "📚 Documentation" "$doc_status"
    
    # Architecture Agent
    col=$((col + box_width + 2))
    draw_agent_box $row $col "🏛️  Architecture" "$arch_status"
    
    # Azure Agent
    col=$((col + box_width + 2))
    draw_agent_box $row $col "☁️  Azure" "$azure_status"
    
    # Audit Agent
    col=$((col + box_width + 2))
    draw_agent_box $row $col "✅ Audit" "$audit_status"
}

# Draw individual agent box
draw_agent_box() {
    local row=$1
    local col=$2
    local title="$3"
    local status="$4"
    local width=26
    local height=5
    
    # Set color based on status
    local color=""
    local status_color=""
    case "$status" in
        running)
            color="${GREEN}"
            status_color="${GREEN}${BOLD}"
            ;;
        error)
            color="${RED}"
            status_color="${RED}${BOLD}"
            ;;
        idle)
            color="${GRAY}"
            status_color="${WHITE}"
            ;;
        *)
            color="${YELLOW}"
            status_color="${YELLOW}${BOLD}"
            ;;
    esac
    
    # Draw box
    tput cup $row $col
    echo -ne "${color}┌"
    printf '─%.0s' $(seq 1 $width)
    echo -ne "┐${NC}"
    
    tput cup $((row + 1)) $col
    echo -ne "${color}│${NC} ${BOLD}$title${NC}"
    local title_len=${#title}
    printf '%*s' $((width - title_len - 1)) ""
    echo -ne "${color}│${NC}"
    
    tput cup $((row + 2)) $col
    echo -ne "${color}│${NC}"
    printf '%*s' $width ""
    echo -ne "${color}│${NC}"
    
    tput cup $((row + 3)) $col
    echo -ne "${color}│${NC}  Status: ${status_color}${status}${NC}"
    local status_len=$((10 + ${#status}))
    printf '%*s' $((width - status_len)) ""
    echo -ne "${color}│${NC}"
    
    tput cup $((row + 4)) $col
    echo -ne "${color}└"
    printf '─%.0s' $(seq 1 $width)
    echo -ne "┘${NC}"
}

# Draw events log
draw_events() {
    local start_row=10
    local width=$(tput cols)
    local max_events=20
    
    tput cup $start_row 0
    echo -ne "${CYAN}${BOLD}Recent Events:${NC}"
    
    tput cup $((start_row + 1)) 0
    echo -ne "${BLUE}"
    printf '%*s' "$width" | tr ' ' '─'
    echo -e "${NC}"
    
    if [ -f "$EVENTS_FILE" ]; then
        local events=$(tail -n $max_events "$EVENTS_FILE" 2>/dev/null | tac)
        local current_row=$((start_row + 2))
        
        while IFS= read -r line; do
            if [ $current_row -ge $(($(tput lines) - 3)) ]; then
                break
            fi
            
            # Parse JSON event
            local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4 | cut -d' ' -f2)
            local agent=$(echo "$line" | grep -o '"agent":"[^"]*"' | cut -d'"' -f4)
            local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
            local details=$(echo "$line" | grep -o '"details":"[^"]*"' | cut -d'"' -f4)
            local level=$(echo "$line" | grep -o '"level":"[^"]*"' | cut -d'"' -f4)
            
            # Set colors based on level
            local level_color=""
            local icon=""
            case "$level" in
                error)
                    level_color="${RED}"
                    icon="✗"
                    ;;
                warning)
                    level_color="${YELLOW}"
                    icon="⚠"
                    ;;
                success)
                    level_color="${GREEN}"
                    icon="✓"
                    ;;
                *)
                    level_color="${CYAN}"
                    icon="ℹ"
                    ;;
            esac
            
            # Format and display event
            tput cup $current_row 2
            echo -ne "${GRAY}$timestamp${NC} "
            echo -ne "${MAGENTA}[$agent]${NC} "
            echo -ne "${level_color}$icon${NC} "
            echo -ne "$action: "
            
            # Truncate details if too long
            local max_details_len=$((width - 40))
            if [ ${#details} -gt $max_details_len ]; then
                details="${details:0:$max_details_len}..."
            fi
            echo -ne "$details"
            
            current_row=$((current_row + 1))
        done <<< "$events"
    else
        tput cup $((start_row + 2)) 2
        echo -ne "${GRAY}No events yet...${NC}"
    fi
}

# Draw status bar
draw_status_bar() {
    local row=$(($(tput lines) - 2))
    local width=$(tput cols)
    
    tput cup $row 0
    echo -ne "${BLUE}"
    printf '%*s' "$width" | tr ' ' '─'
    echo -e "${NC}"
    
    tput cup $((row + 1)) 2
    
    # Check if daemon is running
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -ne "${GREEN}● Daemon Running${NC} (PID: $pid)"
        else
            echo -ne "${RED}● Daemon Stopped${NC}"
        fi
    else
        echo -ne "${GRAY}● Daemon Not Started${NC}"
    fi
    
    # Show commands
    local commands="[Q]uit [R]estart [C]lear [A]udit"
    local cmd_pos=$((width - ${#commands} - 2))
    tput cup $((row + 1)) $cmd_pos
    echo -ne "${WHITE}$commands${NC}"
}

# Handle keyboard input
handle_input() {
    read -t 0.1 -n 1 key 2>/dev/null || true
    
    case "$key" in
        q|Q)
            cleanup
            ;;
        r|R)
            # Restart daemon
            ./claude-agents/daemon/claude-daemon.sh stop 2>/dev/null
            sleep 1
            ./claude-agents/daemon/claude-daemon.sh start &
            ;;
        c|C)
            # Clear events
            > "$EVENTS_FILE"
            ;;
        a|A)
            # Run audit
            claude "As the Audit Orchestration Agent, perform quick audit check" --no-interactive &
            ;;
    esac
}

# Main monitor loop
monitor_loop() {
    while true; do
        draw_header
        draw_agent_status
        draw_events
        draw_status_bar
        
        handle_input
        sleep $REFRESH_RATE
    done
}

# Main execution
main() {
    # Check if in project directory
    if [ ! -d ".git" ]; then
        echo -e "${RED}Error: Not in a git repository${NC}"
        echo "Please run from your project root"
        exit 1
    fi
    
    echo -e "${GREEN}Starting Claude Agents Monitor...${NC}"
    sleep 1
    
    setup_terminal
    monitor_loop
}

main "$@"