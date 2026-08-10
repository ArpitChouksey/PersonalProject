# ==========================================================
# STAGE 1: BUILD
# ==========================================================

FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files first for dependency caching
COPY package*.json ./

RUN npm ci

# Copy application
COPY . .

# Build React application
RUN npm run build


# ==========================================================
# STAGE 2: NGINX
# ==========================================================

FROM nginx:alpine

# Remove default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy React build
COPY --from=builder /app/dist /usr/share/nginx/html

# Nginx runtime configuration template
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Backend configuration defaults
ENV AI_BACKEND_HOST=ai-mcp-client
ENV AI_BACKEND_PORT=8081

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
