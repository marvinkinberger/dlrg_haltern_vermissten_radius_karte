############################
# 1) Fetch source from GitHub
############################
FROM alpine:3.20 AS fetch
RUN apk add --no-cache git sed findutils

ARG REPO_URL="https://github.com/FynnHer/dlrg_landau_services.git"
ARG REPO_REF="main"

WORKDIR /src
RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" .

# --- Refactor + Koordinatenwechsel im Build ---
# 1) Überall im Code LANDAU_COORDS -> HALTERN_COORDS
# 2) In map.js die Koordinaten auf Haltern am See setzen
#
# Haltern am See (Zentrum): [51.7420, 7.1810]
RUN set -eux; \
  find . -type f \( -name "*.js" -o -name "*.html" -o -name "*.css" \) -print0 \
    | xargs -0 sed -i 's/\bLANDAU_COORDS\b/HALTERN_COORDS/g'; \
  if [ -f "./map.js" ]; then \
    sed -i -E 's/const[[:space:]]+HALTERN_COORDS[[:space:]]*=[[:space:]]*\[[^]]+\];/const HALTERN_COORDS = [51.7420, 7.1810];/g' ./map.js; \
  fi

############################
# 2) Serve via Nginx
############################
FROM nginx:1.27-alpine
RUN apk add --no-cache wget

COPY --from=fetch /src/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
