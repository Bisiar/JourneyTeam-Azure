# Claude Agents Daemon System

## Overview

The Claude Agents run as **continuous background daemons** that monitor your codebase and provide real-time feedback through multiple interfaces:

1. **Terminal Daemon** (`claude-daemon.sh`) - Background service with colored output
2. **Terminal Monitor** (`claude-monitor.sh`) - Real-time dashboard UI
3. **MAUI Application** (`ClaudeAgentsUI`) - Cross-platform GUI (Windows, macOS, iOS, Android)

## Installation

### Prerequisites

```bash
# macOS
brew install fswatch

# Linux/WSL
sudo apt-get install inotify-tools

# All platforms
claude --version  # Ensure Claude Code is installed
```

### Quick Setup

```bash
# 1. Make scripts executable
chmod +x claude-agents/daemon/*.sh

# 2. Install dependencies for UI (optional)
cd claude-agents/daemon/ClaudeAgentsUI
dotnet restore
```

## Running the Daemon

### Method 1: Terminal Daemon (Recommended)

Start the daemon in the background with real-time colored output:

```bash
# Start daemon
./claude-agents/daemon/claude-daemon.sh start

# Stop daemon
./claude-agents/daemon/claude-daemon.sh stop

# Check status
./claude-agents/daemon/claude-daemon.sh status

# View logs
./claude-agents/daemon/claude-daemon.sh logs

# Stream events
./claude-agents/daemon/claude-daemon.sh events
```

**What you'll see:**
```
[10:34:12] [architecture] ℹ Analyzing: CustomerService.cs
[10:34:13] [architecture] ✓ Validated: CustomerService.cs
[10:34:15] [azure] ℹ Analyzing: main.bicep
[10:34:16] [azure] ✗ Violation: Storage must be lowercase: Storage-Account-01
[10:34:20] [documentation] ℹ Triggered: Updating WAF documentation
[10:35:45] [documentation] ✓ Complete: Documentation updated
[10:36:00] [audit] ℹ Starting: Checking audit readiness
[10:36:02] [audit] ⚠ Warning: Missing documents: TESTING.md RUNBOOK.md
```

### Method 2: Terminal Monitor UI

Run an interactive terminal dashboard:

```bash
# Start monitor (shows real-time status)
./claude-agents/daemon/claude-monitor.sh
```

**Features:**
- Live agent status boxes showing idle/running/error states
- Scrolling event log with color-coded messages
- Keyboard shortcuts: [Q]uit, [R]estart, [C]lear, [A]udit
- Automatic refresh every second

**Screenshot:**
```
═══════════════════════════════════════════════════════════════
                    Claude Agents Monitor
═══════════════════════════════════════════════════════════════

┌──────────────────────────┐ ┌──────────────────────────┐
│ 📚 Documentation         │ │ 🏛️  Architecture         │
│                          │ │                          │
│  Status: idle            │ │  Status: running         │
└──────────────────────────┘ └──────────────────────────┘

┌──────────────────────────┐ ┌──────────────────────────┐
│ ☁️  Azure                 │ │ ✅ Audit                 │
│                          │ │                          │
│  Status: idle            │ │  Status: idle            │
└──────────────────────────┘ └──────────────────────────┘

Recent Events:
─────────────────────────────────────────────────────────────
10:34:13 [architecture] ✓ Validated: CustomerService.cs
10:34:16 [azure] ✗ Violation: Storage naming invalid
10:35:45 [documentation] ✓ Complete: Documentation updated
10:36:02 [audit] ⚠ Warning: Missing TESTING.md

─────────────────────────────────────────────────────────────
● Daemon Running (PID: 12345)        [Q]uit [R]estart [C]lear
```

### Method 3: MAUI Desktop/Mobile App

Build and run the cross-platform UI:

```bash
# Build for your platform
cd claude-agents/daemon/ClaudeAgentsUI

# macOS
dotnet build -f net8.0-maccatalyst
dotnet run -f net8.0-maccatalyst

# Windows
dotnet build -f net8.0-windows10.0.19041.0
dotnet run -f net8.0-windows10.0.19041.0

# Android (requires emulator/device)
dotnet build -f net8.0-android
dotnet run -f net8.0-android

# iOS (requires Mac with Xcode)
dotnet build -f net8.0-ios
dotnet run -f net8.0-ios
```

**Features:**
- Visual agent status cards with color indicators
- Real-time event log with filtering
- Start/Stop daemon controls
- Manual audit trigger button
- Cross-platform (Windows, macOS, Linux, iOS, Android)

## How the Daemon Works

### File Monitoring
The daemon continuously watches for changes in:
- `/src`, `/Domain`, `/Application`, `/Infrastructure`, `/Web` - Code files
- `/infra` - Azure Bicep templates
- Triggers appropriate agents based on file type

### Agent Activation
- **Architecture Agent**: Validates on `.cs`, `.ts`, `.js` changes
- **Azure Agent**: Validates on `.bicep`, `.json` changes in `/infra`
- **Documentation Agent**: Updates 30 seconds after code changes (debounced)
- **Audit Agent**: Runs hourly or on manual trigger

### Event Levels
- **ℹ Info** (Blue): Normal operations
- **✓ Success** (Green): Validations passed
- **⚠ Warning** (Yellow): Non-critical issues
- **✗ Error** (Red): Violations or failures

## Running as System Service

### macOS (launchd)

```bash
# Create service file
cat > ~/Library/LaunchAgents/com.claude.agents.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.agents</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PWD/claude-agents/daemon/claude-daemon.sh</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$PWD</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# Load service
launchctl load ~/Library/LaunchAgents/com.claude.agents.plist

# Start/stop
launchctl start com.claude.agents
launchctl stop com.claude.agents
```

### Linux (systemd)

```bash
# Create service file
sudo cat > /etc/systemd/system/claude-agents.service << EOF
[Unit]
Description=Claude Agents Daemon
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PWD
ExecStart=$PWD/claude-agents/daemon/claude-daemon.sh start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable claude-agents
sudo systemctl start claude-agents
sudo systemctl status claude-agents
```

### Windows (Task Scheduler)

```powershell
# Create scheduled task (run in PowerShell as admin)
$action = New-ScheduledTaskAction -Execute "wsl.exe" `
    -Argument "cd /path/to/project && ./claude-agents/daemon/claude-daemon.sh start"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "ClaudeAgents" `
    -Action $action -Trigger $trigger -RunLevel Highest
```

## Configuration

### Daemon Settings

Edit `claude-daemon.sh` to customize:

```bash
WATCH_INTERVAL=2        # Seconds between file checks
LOG_FILE=".claude/daemon.log"
EVENTS_FILE=".claude/daemon.events"

# Adjust debounce for documentation updates
sleep 30  # Line 287 - Wait time before doc update
```

### Watched Directories

Modify the directories to monitor:

```bash
# Line 234 in claude-daemon.sh
fswatch -r src Domain Application Infrastructure Web infra custom_dir
```

### Agent Triggers

Customize when agents activate:

```bash
# Line 298 in handle_file_change()
case "$ext" in
    cs|ts|js|java|py|rb|go)  # Add your languages
        check_architecture "$file"
        ;;
    bicep|json|yaml|yml)      # Add config formats
        check_azure_naming "$file"
        ;;
esac
```

## Troubleshooting

### Daemon Won't Start

```bash
# Check if already running
ps aux | grep claude-daemon

# Kill existing process
kill $(cat .claude/daemon.pid)

# Check permissions
chmod +x claude-agents/daemon/*.sh

# Verify Claude is installed
which claude
```

### File Changes Not Detected

```bash
# Install file watchers
# macOS
brew install fswatch

# Linux
sudo apt-get install inotify-tools

# Check watcher is working
fswatch -r src | head -5
```

### Monitor UI Issues

```bash
# Ensure terminal supports colors
echo $TERM  # Should show xterm-256color or similar

# Reset terminal if corrupted
reset
clear
```

### MAUI App Won't Build

```bash
# Update .NET SDK
dotnet --version  # Should be 8.0 or higher

# Install MAUI workload
dotnet workload install maui

# Clear NuGet cache
dotnet nuget locals all --clear
```

## Performance Considerations

### CPU Usage
- File watching is efficient (< 1% CPU)
- Debounced updates prevent excessive Claude calls
- Polling fallback uses more CPU (2-5%)

### Memory Usage
- Daemon: ~10-20 MB
- Monitor: ~5-10 MB  
- MAUI App: ~50-100 MB

### Optimization Tips
1. Exclude large directories (node_modules, bin, obj)
2. Increase debounce time for documentation
3. Use native file watchers (fswatch/inotify)
4. Limit event log to last 100 entries

## Integration with CI/CD

### GitHub Actions

```yaml
name: Claude Agents Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Start Claude Daemon
      run: |
        ./claude-agents/daemon/claude-daemon.sh start
        sleep 5
    
    - name: Check Status
      run: |
        ./claude-agents/daemon/claude-daemon.sh status
        
    - name: Run Validation
      run: |
        # Make changes to trigger agents
        touch src/test.cs
        sleep 10
        
    - name: Check Events
      run: |
        cat .claude/daemon.events | tail -20
        
    - name: Stop Daemon
      if: always()
      run: |
        ./claude-agents/daemon/claude-daemon.sh stop
```

## Best Practices

1. **Start on Boot**: Configure as system service
2. **Monitor Logs**: Check `.claude/daemon.log` regularly
3. **Event Retention**: Clear old events weekly
4. **Resource Limits**: Set max CPU/memory if needed
5. **Notifications**: Integrate with Slack/Teams for errors

## Support

- **Logs**: `.claude/daemon.log`
- **Events**: `.claude/daemon.events`
- **Status**: `.claude/daemon.status`
- **PID**: `.claude/daemon.pid`

The daemon provides continuous, real-time validation and documentation updates, ensuring your code always meets Azure WAF standards and audit requirements.