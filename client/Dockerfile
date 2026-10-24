# ---------- Stage 1: build the React app with Node ----------
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
# Leave VITE_API_URL empty so the app calls /api on the same origin
# (Nginx below proxies /api to the backend container)
ARG VITE_API_URL=""
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build

# ---------- Stage 2: serve the static files with Nginx ----------
# Final image contains only Nginx + the built files (~25 MB), no Node or source code
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
