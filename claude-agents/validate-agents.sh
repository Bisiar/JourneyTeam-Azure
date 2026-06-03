#!/bin/bash

# Validation Script for Azure WAF Agents in Claudia
# This script verifies that all agents are properly installed and configured

set -e

CLAUDIA_DB="$HOME/Library/Application Support/claudia.asterisk.so/agents.db"
EXPECTED_AGENTS=(
    "Code Quality Agent"
    "WAF Documentation Agent"
    "Architecture Enforcement Agent"
    "Azure Infrastructure Agent"
    "Audit Orchestration Agent"
)

echo "========================================="
echo "Azure WAF Agents Validation"
echo "========================================="
echo ""

# Check if database exists
if [ ! -f "$CLAUDIA_DB" ]; then
    echo "❌ Claudia database not found at: $CLAUDIA_DB"
    echo "   Please run ./claudia-setup.sh first"
    exit 1
fi

echo "✅ Claudia database found"
echo ""

# Check each expected agent
echo "Checking for required agents..."
echo "--------------------------------"

missing_agents=()
found_agents=()

for agent in "${EXPECTED_AGENTS[@]}"; do
    result=$(sqlite3 "$CLAUDIA_DB" "SELECT COUNT(*) FROM agents WHERE name = '$agent';")
    
    if [ "$result" -eq "0" ]; then
        echo "❌ Missing: $agent"
        missing_agents+=("$agent")
    else
        echo "✅ Found: $agent"
        found_agents+=("$agent")
    fi
done

echo ""

# Display detailed information about installed agents
if [ ${#found_agents[@]} -gt 0 ]; then
    echo "Installed Agent Details:"
    echo "------------------------"
    
    sqlite3 "$CLAUDIA_DB" <<EOF
.mode column
.headers on
.width 30 10 10 20
SELECT 
    name as "Agent Name",
    icon as "Icon",
    model as "Model",
    datetime(created_at) as "Installed"
FROM agents 
WHERE name IN ($(printf "'%s'," "${found_agents[@]}" | sed 's/,$//' ))
ORDER BY name;
EOF
    
    echo ""
fi

# Check for any unexpected Azure-related agents
echo "Other Azure-related agents found:"
echo "----------------------------------"

other_count=$(sqlite3 "$CLAUDIA_DB" <<EOF
SELECT COUNT(*) FROM agents 
WHERE (name LIKE '%Azure%' OR name LIKE '%WAF%' OR name LIKE '%Audit%')
AND name NOT IN ($(printf "'%s'," "${EXPECTED_AGENTS[@]}" | sed 's/,$//' ));
EOF
)

if [ "$other_count" -gt "0" ]; then
    sqlite3 "$CLAUDIA_DB" <<EOF
.mode column
.headers on
.width 40 10 10
SELECT name, icon, model FROM agents 
WHERE (name LIKE '%Azure%' OR name LIKE '%WAF%' OR name LIKE '%Audit%')
AND name NOT IN ($(printf "'%s'," "${EXPECTED_AGENTS[@]}" | sed 's/,$//' ))
ORDER BY name;
EOF
else
    echo "None found"
fi

echo ""

# Validate agent configurations
echo "Validating agent configurations..."
echo "-----------------------------------"

validation_errors=0

for agent in "${found_agents[@]}"; do
    # Check if system prompt is not empty
    prompt_length=$(sqlite3 "$CLAUDIA_DB" "SELECT LENGTH(system_prompt) FROM agents WHERE name = '$agent' LIMIT 1;")
    
    if [ "$prompt_length" -lt "100" ]; then
        echo "⚠️  Warning: $agent has a very short system prompt ($prompt_length chars)"
        ((validation_errors++))
    fi
    
    # Check if model is valid
    model=$(sqlite3 "$CLAUDIA_DB" "SELECT DISTINCT model FROM agents WHERE name = '$agent' LIMIT 1;" | head -n1)
    if [[ ! "$model" =~ ^(opus|sonnet|haiku)$ ]]; then
        echo "⚠️  Warning: $agent has invalid model: $model"
        ((validation_errors++))
    fi
done

if [ "$validation_errors" -eq "0" ]; then
    echo "✅ All agent configurations are valid"
fi

echo ""

# Summary
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo ""
echo "Expected agents: ${#EXPECTED_AGENTS[@]}"
echo "Found agents: ${#found_agents[@]}"
echo "Missing agents: ${#missing_agents[@]}"
echo "Validation errors: $validation_errors"
echo ""

if [ ${#missing_agents[@]} -eq 0 ] && [ "$validation_errors" -eq 0 ]; then
    echo "✅ All Azure WAF agents are properly installed and configured!"
    echo ""
    echo "You can now launch Claudia with:"
    echo "  ./launch-claudia.sh"
    exit 0
else
    echo "❌ Validation failed. Please run ./claudia-setup.sh to fix issues."
    exit 1
fi