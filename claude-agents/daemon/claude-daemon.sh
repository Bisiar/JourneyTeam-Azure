#!/bin/bash

# Claude Agents Daemon - Continuous monitoring with real-time feedback
# Cross-platform support: macOS, Linux, WSL

set -e

# Configuration
DAEMON_VERSION="1.0.0"
WATCH_INTERVAL=2  # seconds between file checks
LOG_FILE=".claude/daemon.log"
PID_FILE=".claude/daemon.pid"
STATUS_FILE=".claude/daemon.status"
EVENTS_FILE=".claude/daemon.events"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Agent status tracking
declare -A AGENT_STATUS
AGENT_STATUS[documentation]="idle"
AGENT_STATUS[architecture]="idle"
AGENT_STATUS[azure]="idle"
AGENT_STATUS[audit]="idle"

# Initialize daemon
init_daemon() {
    mkdir -p .claude
    touch "$LOG_FILE" "$STATUS_FILE" "$EVENTS_FILE"
    
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo -e "${RED}❌ Daemon already running with PID $OLD_PID${NC}"
            echo "Stop it first with: $0 stop"
            exit 1
        fi
    fi
    
    # Save PID
    echo $$ > "$PID_FILE"
    
    # Initial status
    update_status "starting" "Initializing Claude Agents Daemon v$DAEMON_VERSION"
}

# Update status file (for UI/CLI monitoring)
update_status() {
    local status="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$STATUS_FILE" << EOF
{
  "status": "$status",
  "message": "$message",
  "timestamp": "$timestamp",
  "pid": $$,
  "agents": {
    "documentation": "${AGENT_STATUS[documentation]}",
    "architecture": "${AGENT_STATUS[architecture]}",
    "azure": "${AGENT_STATUS[azure]}",
    "audit": "${AGENT_STATUS[audit]}"
  }
}
EOF
}

# Log event for UI display
log_event() {
    local agent="$1"
    local action="$2"
    local details="$3"
    local level="${4:-info}"  # info, warning, error, success
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Append to events file (keep last 100 events)
    echo "{\"timestamp\":\"$timestamp\",\"agent\":\"$agent\",\"action\":\"$action\",\"details\":\"$details\",\"level\":\"$level\"}" >> "$EVENTS_FILE"
    tail -n 100 "$EVENTS_FILE" > "$EVENTS_FILE.tmp" && mv "$EVENTS_FILE.tmp" "$EVENTS_FILE"
    
    # Also log to file
    echo "[$timestamp] [$agent] $action: $details" >> "$LOG_FILE"
}

# Display event in terminal with colors
display_event() {
    local agent="$1"
    local action="$2"
    local details="$3"
    local level="$4"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        error)
            echo -e "${RED}[$timestamp]${NC} ${MAGENTA}[$agent]${NC} ${RED}✗${NC} $action: $details"
            ;;
        warning)
            echo -e "${YELLOW}[$timestamp]${NC} ${MAGENTA}[$agent]${NC} ${YELLOW}⚠${NC} $action: $details"
            ;;
        success)
            echo -e "${GREEN}[$timestamp]${NC} ${MAGENTA}[$agent]${NC} ${GREEN}✓${NC} $action: $details"
            ;;
        *)
            echo -e "${CYAN}[$timestamp]${NC} ${MAGENTA}[$agent]${NC} ${BLUE}ℹ${NC} $action: $details"
            ;;
    esac
}

# File watcher using different methods based on OS
setup_file_watcher() {
    if command -v fswatch &> /dev/null; then
        # macOS with fswatch
        echo -e "${GREEN}Using fswatch for file monitoring${NC}"
        WATCHER="fswatch"
    elif command -v inotifywait &> /dev/null; then
        # Linux with inotify
        echo -e "${GREEN}Using inotifywait for file monitoring${NC}"
        WATCHER="inotify"
    else
        # Fallback to polling
        echo -e "${YELLOW}Using polling for file monitoring (install fswatch or inotify-tools for better performance)${NC}"
        WATCHER="poll"
    fi
}

# Architecture validation
check_architecture() {
    local file="$1"
    AGENT_STATUS[architecture]="running"
    update_status "running" "Architecture Agent checking $file"
    
    display_event "architecture" "Analyzing" "$file" "info"
    
    # Check for ViewModels in wrong places
    if [[ "$file" == *"Application"* ]] && [[ "$file" == *"ViewModel"* ]]; then
        log_event "architecture" "Violation" "ViewModel in Application layer: $file" "error"
        display_event "architecture" "Violation" "ViewModel in Application layer!" "error"
        
        # Auto-fix suggestion
        local suggested_path="${file/Application/Shared}"
        display_event "architecture" "Suggestion" "Move to: $suggested_path" "warning"
        return 1
    fi
    
    # Check for DB references in Domain
    if [[ "$file" == *"Domain"* ]]; then
        if grep -q "EntityFrameworkCore\|Dapper\|SqlClient" "$file" 2>/dev/null; then
            log_event "architecture" "Violation" "Database reference in Domain: $file" "error"
            display_event "architecture" "Violation" "Database reference in Domain!" "error"
            return 1
        fi
    fi
    
    display_event "architecture" "Validated" "$(basename $file)" "success"
    AGENT_STATUS[architecture]="idle"
    return 0
}

# Azure naming validation
check_azure_naming() {
    local file="$1"
    AGENT_STATUS[azure]="running"
    update_status "running" "Azure Agent checking $file"
    
    display_event "azure" "Analyzing" "$file" "info"
    
    # Extract resource definitions from Bicep
    if [[ "$file" == *".bicep" ]]; then
        # Check resource group naming
        if grep -q "resource.*'Microsoft.Resources/resourceGroups" "$file"; then
            local rg_names=$(grep -oP "name:\s*'[^']+'" "$file" | cut -d"'" -f2)
            for name in $rg_names; do
                if [[ ! "$name" =~ ^rg- ]]; then
                    display_event "azure" "Violation" "Resource group must start with 'rg-': $name" "error"
                    return 1
                fi
            done
        fi
        
        # Check storage account naming
        if grep -q "resource.*'Microsoft.Storage/storageAccounts" "$file"; then
            local storage_names=$(grep -oP "name:\s*'[^']+'" "$file" | cut -d"'" -f2)
            for name in $storage_names; do
                if [[ "$name" =~ [-_] ]] || [[ "$name" =~ [A-Z] ]]; then
                    display_event "azure" "Violation" "Storage must be lowercase alphanumeric only: $name" "error"
                    return 1
                fi
            done
        fi
        
        display_event "azure" "Validated" "All resource names compliant" "success"
    fi
    
    AGENT_STATUS[azure]="idle"
    return 0
}

# Documentation update trigger
trigger_documentation() {
    local files="$1"
    AGENT_STATUS[documentation]="running"
    update_status "running" "Documentation Agent updating"
    
    display_event "documentation" "Triggered" "Updating WAF documentation" "info"
    
    # Run in background
    (
        claude "As the WAF Documentation Agent, update documentation based on recent changes" --no-interactive 2>/dev/null
        if [ $? -eq 0 ]; then
            log_event "documentation" "Updated" "Documentation regenerated" "success"
            display_event "documentation" "Complete" "Documentation updated" "success"
        else
            log_event "documentation" "Failed" "Documentation update failed" "error"
            display_event "documentation" "Failed" "Check logs for details" "error"
        fi
        AGENT_STATUS[documentation]="idle"
    ) &
}

# Audit check (periodic)
run_audit_check() {
    AGENT_STATUS[audit]="running"
    update_status "running" "Audit Agent checking compliance"
    
    display_event "audit" "Starting" "Checking audit readiness" "info"
    
    # Check for required documents
    local missing_docs=()
    for doc in ARCHITECTURE.md OPERATIONS.md SECURITY.md PERFORMANCE.md COST.md; do
        if [ ! -f "$doc" ]; then
            missing_docs+=("$doc")
        fi
    done
    
    if [ ${#missing_docs[@]} -gt 0 ]; then
        display_event "audit" "Warning" "Missing documents: ${missing_docs[*]}" "warning"
        log_event "audit" "Missing" "${missing_docs[*]}" "warning"
    else
        display_event "audit" "Success" "All core documents present" "success"
    fi
    
    AGENT_STATUS[audit]="idle"
}

# Main monitoring loop
monitor_files() {
    local last_doc_update=0
    local last_audit_check=0
    local current_time
    
    display_event "daemon" "Started" "Monitoring for changes..." "success"
    
    case "$WATCHER" in
        fswatch)
            # macOS fswatch
            fswatch -r -e ".*\.git.*" -e ".*node_modules.*" -e ".*\.claude.*" \
                    --event Created --event Updated --event Renamed \
                    src Domain Application Infrastructure Web infra 2>/dev/null | \
            while read file; do
                handle_file_change "$file"
            done &
            ;;
            
        inotify)
            # Linux inotifywait
            inotifywait -mr -e modify,create,move \
                        --exclude "(\.git|node_modules|\.claude)" \
                        src Domain Application Infrastructure Web infra 2>/dev/null | \
            while read path action file; do
                handle_file_change "${path}${file}"
            done &
            ;;
            
        poll)
            # Polling fallback
            while true; do
                find src Domain Application Infrastructure Web infra \
                     -type f -newer "$STATUS_FILE" 2>/dev/null | \
                while read file; do
                    handle_file_change "$file"
                done
                sleep $WATCH_INTERVAL
            done &
            ;;
    esac
    
    # Periodic tasks loop
    while true; do
        current_time=$(date +%s)
        
        # Run audit check every hour
        if [ $((current_time - last_audit_check)) -gt 3600 ]; then
            run_audit_check
            last_audit_check=$current_time
        fi
        
        # Update status heartbeat
        update_status "running" "Monitoring active"
        
        sleep 10
    done
}

# Handle file change events
handle_file_change() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        cs|ts|js|java|py)
            check_architecture "$file"
            # Trigger documentation update after batch of changes
            schedule_documentation_update
            ;;
        bicep|json)
            if [[ "$file" == *"infra"* ]]; then
                check_azure_naming "$file"
            fi
            ;;
        md)
            display_event "daemon" "Detected" "Documentation change: $(basename $file)" "info"
            ;;
    esac
}

# Schedule documentation update (debounced)
DOC_UPDATE_SCHEDULED=0
schedule_documentation_update() {
    if [ $DOC_UPDATE_SCHEDULED -eq 0 ]; then
        DOC_UPDATE_SCHEDULED=1
        (
            sleep 30  # Wait 30 seconds to batch changes
            trigger_documentation
            DOC_UPDATE_SCHEDULED=0
        ) &
    fi
}

# Display dashboard
show_dashboard() {
    clear
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║        Claude Agents Daemon Dashboard v$DAEMON_VERSION        ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Agent Status:${NC}"
    echo -e "  📚 Documentation: ${AGENT_STATUS[documentation]}"
    echo -e "  🏛️  Architecture: ${AGENT_STATUS[architecture]}"
    echo -e "  ☁️  Azure:        ${AGENT_STATUS[azure]}"
    echo -e "  ✅ Audit:        ${AGENT_STATUS[audit]}"
    echo ""
    echo -e "${CYAN}Recent Events:${NC}"
    echo -e "${WHITE}─────────────────────────────────────────────────────────────${NC}"
}

# Signal handlers
cleanup() {
    echo -e "\n${YELLOW}Shutting down daemon...${NC}"
    update_status "stopping" "Daemon shutting down"
    
    # Kill background processes
    jobs -p | xargs -r kill 2>/dev/null
    
    # Remove PID file
    rm -f "$PID_FILE"
    
    update_status "stopped" "Daemon stopped"
    echo -e "${GREEN}Daemon stopped successfully${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Main execution
main() {
    case "${1:-start}" in
        start)
            init_daemon
            setup_file_watcher
            show_dashboard
            monitor_files
            ;;
            
        stop)
            if [ -f "$PID_FILE" ]; then
                PID=$(cat "$PID_FILE")
                kill "$PID" 2>/dev/null && echo -e "${GREEN}Daemon stopped${NC}"
                rm -f "$PID_FILE"
            else
                echo -e "${YELLOW}Daemon not running${NC}"
            fi
            ;;
            
        status)
            if [ -f "$STATUS_FILE" ]; then
                cat "$STATUS_FILE" | python3 -m json.tool 2>/dev/null || cat "$STATUS_FILE"
            else
                echo "Daemon not running"
            fi
            ;;
            
        logs)
            tail -f "$LOG_FILE"
            ;;
            
        events)
            tail -f "$EVENTS_FILE" | while read line; do
                echo "$line" | python3 -m json.tool 2>/dev/null || echo "$line"
            done
            ;;
            
        *)
            echo "Usage: $0 {start|stop|status|logs|events}"
            exit 1
            ;;
    esac
}

main "$@"