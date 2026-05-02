#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/satellite-config.json
OPTIONS_PATH=/data/options.json
APP_ENTRY=/app/satellite/dist/main.js
IS_ROOT=false

if [ "$(id -u)" = "0" ]; then
    IS_ROOT=true
    if ! command -v gosu >/dev/null 2>&1; then
        echo "gosu not found; refusing to start as root." >&2
        exit 1
    fi

    mkdir -p /data
    NODE_UID="$(id -u node)"
    DATA_UID="$(stat -c %u /data)"
    if [ "${DATA_UID}" != "${NODE_UID}" ]; then
        chown -R node:node /data
    fi
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

if ${IS_ROOT}; then
    chown node:node "${CONFIG_PATH}"
    exec gosu node node "${APP_ENTRY}" "${CONFIG_PATH}"
fi

exec node "${APP_ENTRY}" "${CONFIG_PATH}"
