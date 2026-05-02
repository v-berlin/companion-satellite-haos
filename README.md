# companion-satellite-haos

Home Assistant OS add-on repository for
[Bitfocus Companion Satellite](https://github.com/bitfocus/companion-satellite).

Companion Satellite lets you connect USB surfaces (Elgato Stream Deck, Loupedeck, …)
that are physically attached to your Home Assistant host to a
[Bitfocus Companion](https://github.com/bitfocus/companion) instance running anywhere on
your network.

## Add this repository to Home Assistant

1. In Home Assistant open **Settings → Add-ons → Add-on Store**.
2. Click the **⋮ menu** (top-right corner) and choose **Repositories**.
3. Paste the following URL and click **Add**:
   ```
   https://github.com/v-berlin/companion-satellite-haos
   ```
4. Refresh the page – **Companion Satellite** will now appear in the add-on store.
5. Click the add-on, then **Install**.

## Quick-start

After installation:

1. Open the add-on's **Configuration** tab.
2. Set `companion_host` to the IP of your Companion instance (default `127.0.0.1`).
3. Click **Save**, then **Start**.
4. Open the Web UI at `http://<your-ha-ip>:9999` to verify the connection.

For full documentation see [`companion-satellite/README.md`](companion-satellite/README.md).

## Available add-ons

| Add-on | Description |
|--------|-------------|
| [Companion Satellite](companion-satellite/) | USB surface connector for Bitfocus Companion |
