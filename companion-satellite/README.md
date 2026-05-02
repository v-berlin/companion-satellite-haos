# Companion Satellite – Home Assistant Add-on

Runs [Bitfocus Companion Satellite](https://github.com/bitfocus/companion-satellite) as a
Home Assistant add-on so that USB surfaces (Stream Deck, Loupedeck, etc.) physically
connected to the Home Assistant host can be used with Companion running elsewhere on your
network.

## Installation

1. In Home Assistant go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮ menu** (top-right) → **Repositories** and add:
   ```
   https://github.com/v-berlin/companion-satellite-haos
   ```
3. Find **Companion Satellite** in the store and click **Install**.
4. Configure the add-on options (see below) and click **Start**.

## Options

| Option           | Default       | Description                                                                                  |
|------------------|---------------|----------------------------------------------------------------------------------------------|
| `rest_port`      | `9999`        | Port for the Satellite REST API and Web UI. Set to `0` to disable the HTTP server.           |
| `companion_host` | `127.0.0.1`   | IP address or hostname of the Companion instance to connect to.                              |
| `companion_port` | `16622`       | TCP port of the Companion satellite API (default `16622`).                                   |

## Accessing the Web UI

Once the add-on is running, open:

```
http://<your-ha-ip>:9999
```

From there you can set the Companion host/port and manage connected surfaces.

## USB / Stream Deck Support

The add-on enables `usb: true` and `udev: true` so that USB HID devices (Stream Deck,
Loupedeck, etc.) attached directly to the Home Assistant host are passed through into the
container. No extra configuration is needed.

## Host Networking

By default this add-on uses **explicit port mapping** for port `9999/tcp`. This is the
recommended approach and works for the REST API and Web UI.

If you need Companion to **auto-discover** this Satellite via mDNS, you can enable
`host_network: true` in the add-on configuration. Note that with `host_network` the explicit
port mapping is ignored and Satellite will be reachable on whatever port is configured.

## Connecting Companion

Companion (≥ 3.4.0) connects to Satellite over **TCP port 16622**. Make sure Companion is
configured to connect *to* this add-on's host IP (or that Companion auto-discovers it via
mDNS). The Satellite does *not* need to expose port 16622 itself — it dials *out* to
Companion.

## Notes

- Configuration (set via the Web UI) is persisted in `/data/satellite-config.json` inside
  the add-on data directory and survives restarts and updates.
- Add-on options (`companion_host`, `companion_port`, `rest_port`) are applied on every
  start and **overwrite** the corresponding values in the satellite config file. Changes made
  through the Web UI to those same fields will be overwritten on the next restart.
