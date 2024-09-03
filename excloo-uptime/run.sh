#!/bin/sh
tailscaled --socket /var/run/tailscale/tailscaled.sock --state /var/lib/tailscale/tailscaled.state &
tailscale up --authkey ${TAILSCALE_KEY} --hostname ${FLY_APP_NAME}
./gatus
