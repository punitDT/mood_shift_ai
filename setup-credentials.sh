#!/bin/bash

echo "🔐 MoodShift AI - Credentials Setup"
echo "===================================="
echo ""

# Function to setup environment file
setup_env_file() {
    local env_file=$1
    local env_name=$2
    
    echo "Setting up $env_name environment..."
    echo ""
    
    read -p "Enter GROQ_API_KEY: " groq_key
    read -p "Enter AWS_ACCESS_KEY: " aws_access
    read -p "Enter AWS_SECRET_KEY: " aws_secret
    
    cat > "$env_file" << EOF
# MoodShift AI Cloud Functions - $env_name Environment
# Generated on $(date)

# ============================================
# GROQ API
# ============================================
GROQ_API_KEY=$groq_key

# ============================================
# AWS POLLY
# ============================================
AWS_ACCESS_KEY=$aws_access
AWS_SECRET_KEY=$aws_secret
EOF
    
    echo "✅ $env_file created successfully!"
    echo ""
}

# Main menu
echo "Which environment do you want to setup?"
echo "1) Development (.env.dev)"
echo "2) Production (.env.prod)"
echo "3) Both"
echo "4) Exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        setup_env_file "functions/.env.dev" "Development"
        ;;
    2)
        setup_env_file "functions/.env.prod" "Production"
        ;;
    3)
        setup_env_file "functions/.env.dev" "Development"
        setup_env_file "functions/.env.prod" "Production"
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run './deploy-dev.sh' to deploy to development"
echo "2. Run './deploy-prod.sh' to deploy to production"

