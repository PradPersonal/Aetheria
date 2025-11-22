# --- Build stage ---
FROM node:20-alpine AS builder
WORKDIR /app

# install deps (use npm ci for reproducible installs)
COPY package*.json ./
# npm ci requires a package-lock.json; fallback to npm install if ci fails
RUN npm ci --silent || npm install --silent

# copy sources and build
COPY . .
# ARG NODE_ENV=production
# ENV NODE_ENV=$NODE_ENV
RUN npm run build

# --- Production stage ---
#FROM node:20-alpine AS runner
FROM nginx:1.25-alpine AS production
# Replace default config with SPA-friendly config
RUN rm /etc/nginx/conf.d/default.conf || true
# Use the custom nginx.conf from the repo
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built app
COPY --from=builder /app/build /usr/share/nginx/html

# Copy environment template and entrypoint script
COPY public/env.template.js /usr/share/nginx/html/env.template.js
COPY ./public/docker-entrypoint.sh ./docker-entrypoint.sh

# Make entrypoint script executable
RUN chmod +x ./docker-entrypoint.sh

# Set default environment variables
ENV REACT_APP_API_URL=http://localhost:3001/api \
    REACT_APP_STREAMING_URL=http://localhost:3002/api \
    REACT_APP_CHAT_URL=http://localhost:3003/api \
    REACT_APP_CORE_API_URL=http://localhost:3004/api \
    REACT_APP_WS_URL=ws://localhost:3003 \
    REACT_APP_APP_NAME=Aetheria \
    REACT_APP_VERSION=1.0.0 \
    REACT_APP_ENVIRONMENT=production \
    REACT_APP_ENABLE_CHAT=true \
    REACT_APP_ENABLE_ANALYTICS=false \
    REACT_APP_ENABLE_DEBUG=false

# Use custom entrypoint for runtime environment injection
 ENTRYPOINT ["./docker-entrypoint.sh"]
# ENTRYPOINT ["/bin/sh", "-c", "if [ -f /docker-entrypoint.sh ]; then exec /docker-entrypoint.sh \"$@\"; else exec \"$@\"; fi", "--"]

# COPY --from=builder /app/build .

# EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]