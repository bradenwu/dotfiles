#!/bin/bash

# Environment loader for dotfiles
# This script loads environment variables from .env file

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if .env file exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    # Load environment variables from .env file
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
    echo "Environment variables loaded from .env"
else
    echo "Warning: .env file not found. Please create it from .env.example"
fi