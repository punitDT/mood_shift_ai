#!/bin/bash

echo "🔍 Starting MoodShift AI with debug logging..."
echo "📝 Watch for these debug messages:"
echo "   - [GROQ DEBUG] Raw LLM output"
echo "   - [GROQ DEBUG] Parsed response (before cleaning)"
echo "   - [GROQ DEBUG] After cleaning"
echo "   - [POLLY DEBUG] Text received for speaking"
echo "   - [POLLY DEBUG] Before/After cleaning"
echo ""
echo "🎤 Test by speaking something simple like 'I feel tired'"
echo "👀 Look for any spacing issues in the debug output"
echo ""

flutter run

