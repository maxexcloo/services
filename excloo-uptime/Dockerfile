FROM alpine
RUN apk update && apk add ca-certificates ip6tables iptables && rm -rf /var/cache/apk/*
RUN mkdir -p /var/cache/tailscale /var/lib/tailscale /var/run/tailscale
WORKDIR /app
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/local/bin/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/local/bin/tailscale
COPY --from=docker.io/twinproduction/gatus /gatus gatus
COPY config.yaml config/config.yaml
COPY run.sh run.sh
RUN chmod +x run.sh
ENTRYPOINT ["/app/run.sh"]
EXPOSE 8080
