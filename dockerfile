# syntax=docker/dockerfile:1

FROM alpine:3.20 AS fetch
RUN apk add --no-cache git sed findutils

ARG REPO_URL="https://github.com/FynnHer/dlrg_landau_services.git"
ARG REPO_REF="main"

WORKDIR /src
RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" .

# --- Refactor + Koordinatenwechsel im Build ---
RUN set -eux; \
  # 1) Repo-weit LANDAU_COORDS -> HALTERN_COORDS (nur in Web-Dateien)
  find . -type f \( -name "*.js" -o -name "*.html" -o -name "*.css" \) -print0 \
    | xargs -0 sed -i 's/\bLANDAU_COORDS\b/HALTERN_COORDS/g'; \
  \
  # 2) In *jeder* map.js die Konstante auf Haltern am See setzen
  #    (Haltern am See Zentrum: [51.7420, 7.1810])
  find . -type f -name "map.js" -print0 \
    | xargs -0 -I{} sh -c '\
        sed -i -E "s/(const|let|var)[[:space:]]+LANDAU_COORDS[[:space:]]*=[[:space:]]*\\[[^]]+\\];/const HALTERN_COORDS = [51.7420, 7.1810];/g" "{}"; \
        sed -i -E "s/(const|let|var)[[:space:]]+HALTERN_COORDS[[:space:]]*=[[:space:]]*\\[[^]]+\\];/const HALTERN_COORDS = [51.7420, 7.1810];/g" "{}"; \
      '; \
  \
  # 3) OpenRouteService API URL auf lokalen ORS umbiegen
  find . -type f -name "*.js" -print0 \
    | xargs -0 sed -i \
      's#https://api\.openrouteservice\.org/#https://localhost:8081/#g'; \
  \
  # 4) Mini-Check: ist die neue Koordinate wirklich drin?
  grep -R --line-number "HALTERN_COORDS = \\[51\\.7420, 7\\.1810\\]" . || true

FROM nginx:1.27-alpine
RUN apk add --no-cache wget
COPY --from=fetch /src/ /usr/share/nginx/html/

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
