# Build stage
FROM node:20-slim AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (only production)
RUN npm ci --only=production

# Copy source code
COPY . .

# Production image
FROM node:20-slim AS prod
WORKDIR /app

# Copy only production node_modules and app code
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app .

ENV NODE_ENV=production
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Sử dụng user node mặc định của image node
USER node

CMD ["npm", "start"]
