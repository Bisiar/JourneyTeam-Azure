#!/bin/bash

# Update Rust and Build Claudia
# This script updates Rust to the latest version and builds Claudia

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use environment variable or default path for Claudia
CLAUDIA_DIR="${CLAUDIA_DIR:-$HOME/Source/github.com.getAsterisk/claudia}"

echo "========================================="
echo "Update Rust and Build Claudia"
echo "========================================="
echo ""

# Step 1: Update Rust to latest version
echo "1. Updating Rust to latest stable version..."
rustup update stable
rustup default stable

# Show new version
echo "Current Rust version:"
rustc --version
echo ""

# Step 2: Clean previous build artifacts
echo "2. Cleaning previous build artifacts..."
cd "$CLAUDIA_DIR"
cd src-tauri
cargo clean
cd ..
echo "✅ Build artifacts cleaned"
echo ""

# Step 3: Rebuild Claudia
echo "3. Rebuilding Claudia..."
echo "   Installing dependencies..."
bun install

echo "   Building Claudia (debug mode for faster build)..."
bun run tauri build --debug

echo ""
echo "✅ Claudia built successfully!"
echo ""

# Step 4: Run the agent setup
echo "4. Setting up Azure WAF agents..."
cd "$SCRIPT_DIR"
./claudia-setup.sh

echo ""
echo "========================================="
echo "✅ Complete!"
echo "========================================="
echo ""
echo "Claudia has been built with the latest Rust version"
echo "and Azure WAF agents have been integrated."
echo ""
echo "To launch Claudia:"
echo "  ./launch-claudia.sh"