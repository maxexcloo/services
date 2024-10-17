FROM alpine
RUN apk update && apk add ca-certificates ip6tables iptables && rm -rf /var/cache/apk/*
RUN mkdir -p /app /var/cache/tailscale /var/lib/tailscale /var/run/tailscale
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/local/bin/tailscale
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/local/bin/tailscaled
COPY --from=docker.io/twinproduction/gatus /gatus /app/gatus
COPY ../../config/fly-excloo-uptime /app/config
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
ENV GATUS_CONFIG_PATH=/app/config
EXPOSE 8080
