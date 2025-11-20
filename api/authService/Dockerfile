# Stage 1: Build/Install dependencies
FROM node:20-alpine AS development

WORKDIR /app

# Copy package.json and package-lock.json (if exists)
COPY package*.json ./

# Install dependencies
RUN npm install

# Stage 2: Production-ready image
FROM node:20-alpine AS production

WORKDIR /app

# Copy necessary files from the development stage
COPY --from=development /app/node_modules ./node_modules
COPY . .

# Set the environment to production
ENV NODE_ENV=production

# Expose the port your Express app runs on (default is often 3000 or 8080)
EXPOSE 3000

# Command to start the application using the "start" script
# Note: Since nodemon is only for development, the index.js is started directly for production
CMD ["node", "index.js"]
