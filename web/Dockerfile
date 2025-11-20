# --- Build stage ---
FROM node:20-alpine AS builder
WORKDIR /app

# install deps (use npm ci for reproducible installs)
COPY package*.json ./
# npm ci requires a package-lock.json; fallback to npm install if ci fails
RUN npm ci --silent || npm install --silent

# copy sources and build
COPY . .
ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV
RUN npm run build

# --- Production stage ---
#FROM node:20-alpine AS runner
FROM nginx:1.25-alpine AS production
# Replace default config with SPA-friendly config (will be created if nginx.conf not provided)
RUN rm /etc/nginx/conf.d/default.conf || true
# If you have a custom nginx.conf in repo, uncomment the next line to use it:
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# fallback: create a minimal SPA nginx config
RUN printf 'server {\n  listen 80;\n  server_name _;\n  root /usr/share/nginx/html;\n  index index.html;\n  location / {\n    try_files $uri $uri/ /index.html;\n  }\n  location /static/ {\n    expires 30d;\n  }\n}\n' > /etc/nginx/conf.d/default.conf

# Copy built app
COPY --from=builder /app/build /usr/share/nginx/html

# copy env template into build output (so it's served)
COPY public/env.template.js /usr/share/nginx/html/env.template.js
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]