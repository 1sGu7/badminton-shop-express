FROM node:20-slim

# Tối ưu cho RAM thấp, chỉ cài đúng production dependencies
WORKDIR /app

# Copy package files trước để cache layer npm install
COPY package*.json ./
RUN npm ci --only=production --no-optional && npm cache clean --force;

# Copy source code (chỉ những gì cần thiết)
COPY . .

ENV NODE_ENV=production
EXPOSE 3000

# Health check đơn giản, không tốn RAM
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

# Sử dụng user node mặc định của image node
USER node

CMD ["npm", "start"]