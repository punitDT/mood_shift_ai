#!/bin/bash

echo "🧪 Testing MoodShift AI Cloud Functions"
echo "========================================"
echo ""

# Function to test endpoint
test_endpoint() {
    local env_name=$1
    local url=$2
    
    echo "Testing $env_name environment..."
    echo "URL: $url"
    echo ""
    
    # Simple health check (will fail without App Check token, but shows function is running)
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d '{"deviceId":"test","text":"hello"}')
    
    if [ "$response" == "401" ]; then
        echo "✅ Function is running (401 = App Check required, which is expected)"
    elif [ "$response" == "200" ]; then
        echo "✅ Function is running and responding"
    else
        echo "⚠️  Unexpected response code: $response"
    fi
    echo ""
}

# Menu
echo "Which environment do you want to test?"
echo "1) Development"
echo "2) Production"
echo "3) Both"
echo "4) Exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        test_endpoint "Development" "https://us-central1-mood-shift-ai-dev.cloudfunctions.net/processUserInput"
        ;;
    2)
        test_endpoint "Production" "https://us-central1-mood-shift-ai.cloudfunctions.net/processUserInput"
        ;;
    3)
        test_endpoint "Development" "https://us-central1-mood-shift-ai-dev.cloudfunctions.net/processUserInput"
        test_endpoint "Production" "https://us-central1-mood-shift-ai.cloudfunctions.net/processUserInput"
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

echo "📊 To view detailed logs, run:"
echo "  firebase functions:log -P dev      # Development"
echo "  firebase functions:log -P default  # Production"

