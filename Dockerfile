# ============================================================
#  Dockerfile del frontend (Vite + React) servido con nginx
#  Va en la RAÍZ del repositorio, al lado del package.json
#
#  Dos etapas:
#   1. "build": Node compila el sitio y deja los archivos en dist/
#   2. final:   nginx sirve esos archivos. Sin Node, sin código fuente.
# ============================================================

# ---------- Etapa 1: compilar ----------
FROM node:22-alpine AS build
WORKDIR /app

# Primero solo las dependencias: si no cambian, Docker reutiliza esta capa
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# La dirección de la API queda ESCRITA dentro del JavaScript al compilar.
# Por defecto "/api": nginx reenvía esas llamadas al backend (ver nginx/).
ARG VITE_API_BASE_URL=
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
RUN npm run build

# ---------- Etapa 2: servir ----------
FROM nginx:1.27-alpine

# Plantilla de configuración: al arrancar, nginx reemplaza ${BACKEND_URL}
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html

# Hacia dónde reenviar /api. Se puede cambiar al correr el contenedor:
#   docker run -e BACKEND_URL=https://mi-backend.onrender.com ...
ENV BACKEND_URL=http://backend:8080
# Hace que nginx use el DNS del contenedor (Docker o Kubernetes)
ENV NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1

EXPOSE 3000
