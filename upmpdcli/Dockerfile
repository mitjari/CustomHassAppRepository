# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
# We layer on top of the upstream multi-arch giof71/upmpdcli image rather than
# rebuilding upmpdcli from scratch. Our wrapper renders the HA options into
# /user/config/upmpdcli-additional.txt and then execs upstream's entrypoint.
FROM giof71/upmpdcli:latest

# jq parses /data/options.json. Upstream is debian-slim and doesn't ship it.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /
RUN chmod +x /app/bin/ha-wrapper.sh

ENTRYPOINT ["/app/bin/ha-wrapper.sh"]

LABEL \
    org.opencontainers.image.title="Home Assistant App: upmpdcli" \
    org.opencontainers.image.description="Subsonic-to-UPnP/DLNA bridge wrapping giof71/upmpdcli." \
    org.opencontainers.image.source="https://github.com/mitjari/CustomHassAppRepository" \
    org.opencontainers.image.licenses="Apache License 2.0"
