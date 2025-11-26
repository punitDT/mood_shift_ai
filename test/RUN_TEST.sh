#!/bin/bash

# AWS Polly SSML Features Test Runner
# This script runs the comprehensive SSML features test

echo "═══════════════════════════════════════════════════════════════"
echo "🧪 AWS Polly SSML Features Test Runner"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "Please create a .env file with AWS credentials"
    exit 1
fi

# Extract AWS credentials from .env
AWS_ACCESS_KEY=$(grep AWS_ACCESS_KEY .env | cut -d '=' -f2 | tr -d ' "')
AWS_SECRET_KEY=$(grep AWS_SECRET_KEY .env | cut -d '=' -f2 | tr -d ' "')

# Check if credentials are set
if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
    echo "❌ Error: AWS credentials not found in .env"
    echo "Please set AWS_ACCESS_KEY and AWS_SECRET_KEY in .env"
    exit 1
fi

echo "✅ AWS credentials loaded from .env"
echo ""

# Run the test
echo "🚀 Running SSML features test..."
echo ""

dart test/test_polly_ssml_features.dart "$AWS_ACCESS_KEY" "$AWS_SECRET_KEY"

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "✅ Test completed successfully!"
    echo "═══════════════════════════════════════════════════════════════"
else
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "❌ Test failed. Please check the output above."
    echo "═══════════════════════════════════════════════════════════════"
    exit 1
fi
