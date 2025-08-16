# Claude Agents Activation Guide

## Why Your Agents Didn't Help (And How to Fix It)

Your agents didn't assist with the Azure naming issue because they weren't activated. Here are **ALL** the ways to ensure they work:

## 🚀 Option 1: Automatic Activation (Recommended)

### Install the Claude Wrapper
This replaces your `claude` command with a wrapper that auto-starts agents:

```bash
# 1. Make the wrapper executable
chmod +x /Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/claude-wrapper.sh

# 2. Install it (adds alias to your shell)
/Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/claude-wrapper.sh --install

# 3. Reload your shell
source ~/.zshrc  # or ~/.bashrc

# 4. Now 'claude' automatically starts agents!
claude "Create infrastructure for my project"
# Agents start automatically and validate output
```

### What the Wrapper Does:
- ✅ Starts daemon automatically when you use `claude`
- ✅ Injects agent context into your prompts
- ✅ Shows agent status after commands
- ✅ Enhances prompts for infrastructure/architecture tasks

### New Commands Available:
```bash
claude agents status    # Check agent status
claude agents start     # Manually start daemon
claude agents stop      # Stop daemon
claude agents monitor   # Open monitoring UI
claude agents logs      # View agent logs
```

## 🎯 Option 2: Project-Level Configuration

### Add CLAUDE.md to Your Project
Copy the agent instructions to your project root:

```bash
# Copy to your project
cp /Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/CLAUDE_PROJECT.md /Users/james/Source/bisiar.github.com/Reflections/CLAUDE.md

# This tells Claude about your agents and rules
```

### What This Does:
- ✅ Claude reads CLAUDE.md automatically
- ✅ Enforces naming patterns (no more resourceToken!)
- ✅ Enforces architecture rules
- ✅ Maintains documentation standards

## 🔧 Option 3: Manual Daemon Control

### Start Before Working
```bash
# Navigate to your project
cd /Users/james/Source/bisiar.github.com/Reflections

# Start the daemon
/Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/daemon/claude-daemon.sh start

# Now work normally - agents monitor everything
claude "Create Bicep templates"
# Files are monitored and validated in real-time
```

### Monitor in Real-Time
```bash
# Open monitoring dashboard
/Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/daemon/claude-monitor.sh

# See live agent activity and violations
```

## 🎨 Option 4: Explicit Agent Invocation

### Call Agents Directly in Prompts
```bash
# For infrastructure
claude "As the Azure Infrastructure Agent, create Bicep templates for 'reflections' with proper naming"

# For architecture
claude "As the Architecture Enforcement Agent, review my code structure"

# For documentation
claude "As the WAF Documentation Agent, update my project documentation"

# For audit
claude "As the Audit Orchestration Agent, check my compliance"
```

## 🔄 Option 5: Git Hooks Integration

### Already Installed by setup.sh
If you ran the setup script, git hooks are active:

```bash
# Pre-commit: Validates architecture and naming
git commit -m "Add feature"
# ❌ ERROR: ViewModels detected in Application layer!

# Post-commit: Updates documentation
git commit -m "Update infrastructure"
# 📚 Updating WAF documentation...
```

## 🖥️ Option 6: System Service (Always On)

### macOS (Launch Agent)
```bash
# Create launch agent
cat > ~/Library/LaunchAgents/com.claude.agents.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.agents</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/daemon/claude-daemon.sh</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/james/Source/bisiar.github.com/Reflections</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/claude-agents.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-agents.error.log</string>
</dict>
</plist>
EOF

# Load and start
launchctl load ~/Library/LaunchAgents/com.claude.agents.plist
launchctl start com.claude.agents

# Now agents run automatically on system startup!
```

## 📱 Option 7: Desktop Monitoring App

### Build and Run MAUI App
```bash
cd /Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/daemon/ClaudeAgentsUI
dotnet run -f net8.0-maccatalyst

# Visual monitoring with start/stop controls
```

## 🔍 How to Verify Agents Are Working

### Check Status
```bash
# If using wrapper
claude agents status

# Or directly
cat .claude/daemon.status | jq '.'
```

### Watch Events
```bash
# Real-time events
tail -f .claude/daemon.events | jq '.'
```

### Test Validation
```bash
# Create a file with wrong naming
echo "var resourceToken = uniqueString()" > test.bicep

# Should see:
# [azure] ✗ Violation: Use project name not resourceToken
```

## ⚡ Quick Start for Your Reflections Project

```bash
# 1. Install wrapper (one time)
/Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/claude-wrapper.sh --install
source ~/.zshrc

# 2. Copy CLAUDE.md to project
cp /Users/james/Source/bisiar.github.com/JourneyTeam-Azure/claude-agents/CLAUDE_PROJECT.md /Users/james/Source/bisiar.github.com/Reflections/CLAUDE.md

# 3. Navigate to project
cd /Users/james/Source/bisiar.github.com/Reflections

# 4. Use Claude normally - agents now active!
claude "Update my Bicep templates to use 'reflections' not resourceToken"
# Agents validate automatically
```

## 🎯 What Would Have Prevented Your Issue

If agents were active, when you asked Claude to scaffold infrastructure:

1. **Azure Agent** would have caught: `var resourceToken = uniqueString()`
2. **Claude** would have received: "Use project name 'reflections' not resourceToken"
3. **Result**: `rg-reflections-prod` instead of `rg-6b2s6nhalemmo`

## 📊 Agent Priority Order

1. **Wrapper Method** - Best for always-on protection
2. **CLAUDE.md** - Best for project-specific rules
3. **Manual Daemon** - Best for development sessions
4. **Git Hooks** - Best for commit validation
5. **System Service** - Best for CI/CD environments

## 🚨 Common Issues and Fixes

### "Agents didn't catch my issue"
- **Check**: Are agents running? `claude agents status`
- **Fix**: Install wrapper or start daemon

### "Claude still uses resourceToken"
- **Check**: Is CLAUDE.md in project root?
- **Fix**: Copy CLAUDE_PROJECT.md to your project as CLAUDE.md

### "Wrapper command not found"
- **Check**: Did you reload shell after install?
- **Fix**: `source ~/.zshrc` or open new terminal

### "Daemon won't start"
- **Check**: Are you in a git repository?
- **Fix**: `git init` or navigate to project root

## 📝 Summary

Your agents didn't help because they weren't activated. Choose one or more methods above to ensure they're always protecting your code:

- **Easiest**: Install wrapper (Option 1)
- **Most Portable**: Add CLAUDE.md (Option 2)
- **Most Visible**: Use monitor UI (Option 3)
- **Most Integrated**: Git hooks (Option 5)
- **Always On**: System service (Option 6)

Remember: **Agents only help if they're running!**