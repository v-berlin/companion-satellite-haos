#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/satellite-config.json
OPTIONS_PATH=/data/options.json

if [ "$(id -u)" = "0" ] && [ -z "${RUN_AS_NODE:-}" ]; then
    if ! command -v gosu >/dev/null 2>&1; then
        echo "gosu not found; refusing to start as root." >&2
        exit 1
    fi

    SCRIPT_PATH="${BASH_SOURCE[0]}"
    mkdir -p /data
    chown -R --no-dereference node:node /data
    exec gosu node env RUN_AS_NODE=1 "${SCRIPT_PATH}" "$@"
fi

# Read options written by Home Assistant Supervisor into /data/options.json
REST_PORT="$(jq -r '.rest_port // 9999' "${OPTIONS_PATH}")"
COMPANION_HOST="$(jq -r '.companion_host // "127.0.0.1"' "${OPTIONS_PATH}")"
COMPANION_PORT="$(jq -r '.companion_port // 16622' "${OPTIONS_PATH}")"

# Seed the satellite config file the first time (conf library will maintain it
# afterwards; we only set values when the file does not already contain them so
# that changes made through the Web UI are preserved across restarts).
if [ ! -f "${CONFIG_PATH}" ]; then
    echo "{}" > "${CONFIG_PATH}"
fi

# Apply option values into the JSON config unconditionally so that
# changes to the add-on options always take effect.
# All values are passed as strings and converted to the correct type inside jq
# to avoid failures if the shell variables ever contain unexpected characters.
UPDATED="$(jq \
    --arg rest_port "${REST_PORT}" \
    --arg companion_host "${COMPANION_HOST}" \
    --arg companion_port "${COMPANION_PORT}" \
    '.restPort = ($rest_port | tonumber) |
     .restEnabled = (($rest_port | tonumber) > 0) |
     .remoteIp = $companion_host |
     .remotePort = ($companion_port | tonumber)' \
    "${CONFIG_PATH}")"

echo "${UPDATED}" > "${CONFIG_PATH}"

exec node /app/satellite/dist/main.js "${CONFIG_PATH}"
