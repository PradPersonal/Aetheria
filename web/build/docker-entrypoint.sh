#!/bin/sh

# Function to replace environment variables in template
replace_env_vars() {
  local template_file="$1"
  local output_file="$2"
  
  # Start with the template
  cp "$template_file" "$output_file"
  
  # Replace environment variables with their actual values
  for env_var in $(printenv | grep '^REACT_APP_' | cut -d '=' -f 1); do
    env_value=$(printenv "$env_var")
    # Escape special characters for sed
    env_value_escaped=$(echo "$env_value" | sed 's/[[\.*^$()+?{|]/\\&/g')
    # Replace the placeholder with the actual value
    sed -i "s|%%${env_var}%%|${env_value_escaped}|g" "$output_file"
  done
}

# Set default values if not provided
export REACT_APP_API_URL=${REACT_APP_API_URL:-"http://localhost:3001/api"}
export REACT_APP_STREAMING_URL=${REACT_APP_STREAMING_URL:-"http://localhost:3002/api"}
export REACT_APP_CHAT_URL=${REACT_APP_CHAT_URL:-"http://localhost:3003/api"}
export REACT_APP_CORE_API_URL=${REACT_APP_CORE_API_URL:-"http://localhost:3004/api"}
export REACT_APP_WS_URL=${REACT_APP_WS_URL:-"ws://localhost:3003"}
export REACT_APP_APP_NAME=${REACT_APP_APP_NAME:-"Aetheria"}
export REACT_APP_VERSION=${REACT_APP_VERSION:-"1.0.0"}
export REACT_APP_ENVIRONMENT=${REACT_APP_ENVIRONMENT:-"production"}

echo "🚀 Starting Aetheria Frontend"
echo "📦 Environment: $REACT_APP_ENVIRONMENT"
echo "🔗 API URL: $REACT_APP_API_URL"
echo "🎬 Streaming URL: $REACT_APP_STREAMING_URL"
echo "💬 Chat URL: $REACT_APP_CHAT_URL"
echo "⚡ Core API URL: $REACT_APP_CORE_API_URL"

# Generate runtime environment configuration
echo "🔧 Generating runtime environment configuration..."
replace_env_vars "/usr/share/nginx/html/env.template.js" "/usr/share/nginx/html/env.js"

echo "✅ Environment configuration generated successfully"
echo "🌐 Starting nginx..."

# Execute the original command (nginx)
exec "$@"