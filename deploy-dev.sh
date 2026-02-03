#!/bin/bash

# Deploy to Development Environment
echo "🚀 Deploying to Development (mood-shift-ai-dev)..."

# Copy dev environment file
if [ -f "functions/.env.dev" ]; then
    cp functions/.env.dev functions/.env
    echo "✓ Copied .env.dev to .env"
else
    echo "❌ Error: functions/.env.dev not found!"
    echo "Please create functions/.env.dev with your development credentials"
    exit 1
fi

# Deploy to dev project
firebase deploy --only functions -P dev

# Clean up
rm functions/.env
echo "✓ Cleaned up .env file"

echo "✅ Development deployment complete!"

