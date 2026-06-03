#!/bin/bash

# Claudia Setup and Azure WAF Agents Integration Script
# This script builds Claudia from source and integrates Azure WAF agents

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use environment variable or default path for Claudia
CLAUDIA_DIR="${CLAUDIA_DIR:-$HOME/Source/github.com.getAsterisk/claudia}"

# Agents directory is where this script lives
AGENTS_DIR="$SCRIPT_DIR"
CLAUDIA_DB_DIR="$HOME/Library/Application Support/claudia.asterisk.so"

echo "========================================="
echo "Claudia Azure WAF Agents Integration"
echo "========================================="
echo ""

# Step 1: Check prerequisites
echo "1. Checking prerequisites..."

if ! command -v bun &> /dev/null; then
    echo "❌ Bun is not installed. Installing..."
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
else
    echo "✅ Bun is installed"
fi

if ! command -v rustc &> /dev/null; then
    echo "❌ Rust is not installed. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "✅ Rust is installed"
fi

if ! command -v claude &> /dev/null; then
    echo "⚠️  Claude Code CLI not found in PATH"
    echo "   Please install from https://claude.ai/code"
else
    echo "✅ Claude Code CLI is installed"
fi

# Step 2: Build Claudia
echo ""
echo "2. Building Claudia from source..."

# Check if Claudia directory exists
if [ ! -d "$CLAUDIA_DIR" ]; then
    echo "❌ Claudia directory not found at: $CLAUDIA_DIR"
    echo ""
    echo "Please either:"
    echo "  1. Clone Claudia: git clone https://github.com/getAsterisk/claudia.git $CLAUDIA_DIR"
    echo "  2. Set CLAUDIA_DIR environment variable to your Claudia location"
    echo "     export CLAUDIA_DIR=/path/to/claudia"
    exit 1
fi

cd "$CLAUDIA_DIR"

# Install dependencies
echo "   Installing dependencies..."
bun install

# Build for development (faster)
echo "   Building Claudia..."
bun run tauri build --debug

echo "✅ Claudia built successfully"

# Step 3: Create database directory if it doesn't exist
echo ""
echo "3. Setting up Claudia database..."
mkdir -p "$CLAUDIA_DB_DIR"

# Step 4: Initialize database and add agents
echo ""
echo "4. Creating agents database..."

# Create the SQLite database and agents table
sqlite3 "$CLAUDIA_DB_DIR/agents.db" <<EOF
-- Create agents table if not exists
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    icon TEXT NOT NULL,
    system_prompt TEXT NOT NULL,
    default_task TEXT,
    model TEXT DEFAULT 'sonnet',
    permissions TEXT DEFAULT '{"file_read":true,"file_write":true,"network":false}',
    hooks TEXT DEFAULT '{}',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Clear existing Azure WAF agents (if any)
DELETE FROM agents WHERE name LIKE '%WAF%' OR name LIKE '%Azure%' OR name LIKE '%Audit%' OR name LIKE '%Architecture%' OR name LIKE '%Code Quality%';
EOF

echo "✅ Database initialized"

# Step 5: Insert Azure WAF agents
echo ""
echo "5. Adding Azure WAF agents..."

# Read system prompts from the JSON files
for json_file in "$AGENTS_DIR/claudia-format"/*.claudia.json; do
    if [ -f "$json_file" ]; then
        echo "   Processing $(basename "$json_file")..."
        
        # Extract agent data using Python (more reliable for JSON parsing)
        python3 - "$json_file" "$CLAUDIA_DB_DIR/agents.db" <<'PYTHON_SCRIPT'
import json
import sqlite3
import sys

json_file = sys.argv[1]
db_path = sys.argv[2]

with open(json_file, 'r') as f:
    data = json.load(f)
    
agent = data.get('agent', {})
name = agent.get('name', 'Unknown Agent')
icon = agent.get('icon', 'code')
system_prompt = agent.get('system_prompt', '')
default_task = agent.get('default_task', '')
model = agent.get('model', 'sonnet')

# Connect to database
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Insert or replace agent
cursor.execute('''
    INSERT OR REPLACE INTO agents (name, icon, system_prompt, default_task, model)
    VALUES (?, ?, ?, ?, ?)
''', (name, icon, system_prompt, default_task, model))

conn.commit()
conn.close()

print(f"   ✅ Added: {name}")
PYTHON_SCRIPT
    fi
done

# Step 6: Verify agents were added
echo ""
echo "6. Verifying agent installation..."
echo ""
echo "Installed Azure WAF Agents:"
echo "----------------------------"

sqlite3 "$CLAUDIA_DB_DIR/agents.db" <<EOF
.mode column
.headers on
.width 30 10 10
SELECT name, icon, model FROM agents 
WHERE name LIKE '%WAF%' 
   OR name LIKE '%Azure%' 
   OR name LIKE '%Audit%' 
   OR name LIKE '%Architecture%' 
   OR name LIKE '%Code Quality%'
ORDER BY name;
EOF

# Step 7: Create launcher script
echo ""
echo "7. Creating launcher script..."

cat > "$AGENTS_DIR/launch-claudia.sh" <<LAUNCHER
#!/bin/bash

# Claudia Launcher Script

# Use environment variable or default path
CLAUDIA_DIR="\${CLAUDIA_DIR:-\$HOME/Source/github.com.getAsterisk/claudia}"
CLAUDIA_APP="\$CLAUDIA_DIR/src-tauri/target/debug/claudia"

if [ -f "\$CLAUDIA_APP" ]; then
    echo "Launching Claudia with Azure WAF agents..."
    "\$CLAUDIA_APP"
else
    echo "Error: Claudia not found at \$CLAUDIA_APP"
    echo "Please run claudia-setup.sh first to build Claudia"
    echo "Or set CLAUDIA_DIR environment variable to your Claudia location"
    exit 1
fi
LAUNCHER

chmod +x "$AGENTS_DIR/launch-claudia.sh"

# Step 8: Create agent export script
echo ""
echo "8. Creating agent export script..."

cat > "$AGENTS_DIR/export-agents.sh" <<'EXPORT'
#!/bin/bash

# Export Azure WAF agents from Claudia database

DB_PATH="$HOME/Library/Application Support/claudia.asterisk.so/agents.db"
EXPORT_DIR="./exported-agents"

mkdir -p "$EXPORT_DIR"

echo "Exporting Azure WAF agents..."

sqlite3 "$DB_PATH" <<EOF | while IFS='|' read -r id name; do
.mode list
.separator "|"
SELECT id, name FROM agents 
WHERE name LIKE '%WAF%' 
   OR name LIKE '%Azure%' 
   OR name LIKE '%Audit%' 
   OR name LIKE '%Architecture%' 
   OR name LIKE '%Code Quality%';
EOF
    echo "Exporting: $name"
    
    sqlite3 "$DB_PATH" <<SQL > "$EXPORT_DIR/${name// /-}.json"
.mode json
SELECT * FROM agents WHERE id = $id;
SQL
done

echo "Agents exported to $EXPORT_DIR"
EXPORT

chmod +x "$AGENTS_DIR/export-agents.sh"

# Step 9: Summary
echo ""
echo "========================================="
echo "✅ Claudia Setup Complete!"
echo "========================================="
echo ""
echo "Azure WAF agents have been successfully integrated into Claudia."
echo ""
echo "To launch Claudia:"
echo "  ./launch-claudia.sh"
echo ""
echo "Or run directly:"
echo "  \$CLAUDIA_DIR/src-tauri/target/debug/claudia"
echo ""
echo "To verify agents in database:"
echo "  sqlite3 '$CLAUDIA_DB_DIR/agents.db' 'SELECT name FROM agents;'"
echo ""
echo "To export agents:"
echo "  ./export-agents.sh"
echo ""
echo "Enjoy using Claudia with Azure WAF compliance agents!"