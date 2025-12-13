#!/bin/sh
set -e

# Inject environment variables into env.js at runtime
envsubst < /usr/share/nginx/html/env.template.js > /usr/share/nginx/html/env.js

exec "$@"