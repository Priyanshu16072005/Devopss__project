# ---------- Food For All API (Node.js + Express) ----------
# Small Alpine base instead of the ~1 GB full node image
FROM node:20-alpine

WORKDIR /app
ENV NODE_ENV=production

# Copy only the dependency manifests first so this layer is cached
# and `npm ci` re-runs only when dependencies change
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy the source code (see .dockerignore for what is excluded)
COPY --chown=node:node . .

# Never run the app as root inside the container
USER node

EXPOSE 5000

# Docker marks the container "unhealthy" if /api/health stops answering
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:5000/api/health || exit 1

# Run node directly (not via npm) so SIGTERM reaches the app for graceful shutdown
CMD ["node", "index.js"]
