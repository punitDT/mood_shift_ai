#!/bin/bash

# Delete and redeploy to Production Environment
echo "🗑️  Deleting existing function from Production..."

# Delete the existing function
firebase functions:delete processUserInput -P default --force

echo ""
echo "🚀 Deploying fresh to Production (mood-shift-ai)..."

# Copy prod environment file
if [ -f "functions/.env.prod" ]; then
    cp functions/.env.prod functions/.env
    echo "✓ Copied .env.prod to .env"
else
    echo "❌ Error: functions/.env.prod not found!"
    echo "Please create functions/.env.prod with your production credentials"
    exit 1
fi

# Deploy to prod project
firebase deploy --only functions -P default

# Clean up
rm functions/.env
echo "✓ Cleaned up .env file"

echo "✅ Production deployment complete!"

