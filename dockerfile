############################
# 1) Fetch source from GitHub
############################
FROM alpine:3.20 AS fetch
RUN apk add --no-cache git

ARG REPO_URL="https://github.com/FynnHer/dlrg_landau_services.git"
ARG REPO_REF="main"

WORKDIR /src
RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" .

############################
# 2) Serve via Nginx
############################
FROM nginx:1.27-alpine

# Optional: basic healthcheck (needs wget)
RUN apk add --no-cache wget

# Copy static files into Nginx web root
COPY --from=fetch /src/ /usr/share/nginx/html/

# If you want to serve a specific entry file instead:
# (not needed here, since index.html exists at repo root)
# RUN test -f /usr/share/nginx/html/index.html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
 
