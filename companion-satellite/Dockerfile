# ---------------------------------------------------------------------------
# Stage 1 – build
# Clone upstream companion-satellite, install deps, build TypeScript, and
# apply the same libusb/node-usb/node-hid patches as the upstream Dockerfile
# so that USB devices work inside a container (no udev inside Docker).
# ---------------------------------------------------------------------------
FROM node:24-bookworm AS build

WORKDIR /app

# Runtime system deps required for native module compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        unzip \
        libusb-1.0-0-dev \
        libudev-dev \
        cmake \
        python3 \
        make \
        g++ \
    && rm -rf /var/lib/apt/lists/*

# Pin to a specific upstream release tag for reproducible builds.
# Check https://github.com/bitfocus/companion-satellite/releases for the latest tag.
# Override at build time with: --build-arg SATELLITE_REF=v3.0.1
ARG SATELLITE_REF=v3.0.1
RUN git clone --depth 1 --branch "${SATELLITE_REF}" \
        https://github.com/bitfocus/companion-satellite.git /app

# Enable corepack so yarn 4 (defined in packageManager field) is available
RUN corepack enable && corepack prepare

RUN yarn config set networkTimeout 100000
RUN yarn install --immutable
RUN yarn build
# Reinstall production-only deps to slim down the output
RUN yarn workspaces focus --all --production

# ---------------------------------------------------------------------------
# Patch node-usb: disable udev (udev is not available inside Docker)
# ---------------------------------------------------------------------------
RUN sed -i "s/'use_udev%': 1/'use_udev%': 0/" node_modules/usb/libusb.gypi \
    && cd node_modules/usb && rm -rf prebuilds && yarn node-gyp-build

# ---------------------------------------------------------------------------
# Patch node-hid: make it use the same libusb version as node-usb so that
# freshly plugged-in devices are detected correctly.
# ---------------------------------------------------------------------------
ADD https://github.com/libusb/libusb/archive/e782eeb2514266f6738e242cdcb18e3ae1ed06fa.zip \
        node_modules/node-hid/libusb.zip
ADD https://raw.githubusercontent.com/node-usb/node-usb/52b879c91df3fc594832d37081c9c3bf4b02d064/libusb.gypi \
        node_modules/node-hid/libusb.gypi
RUN cd node_modules/node-hid \
    && unzip libusb.zip \
    && mv libusb-e782eeb2514266f6738e242cdcb18e3ae1ed06fa libusb
RUN sed -i "s/'use_udev%': 1/'use_udev%': 0/" node_modules/node-hid/libusb.gypi
RUN mkdir -p node_modules/node-hid/libusb_config \
    && touch node_modules/node-hid/libusb_config/config.h
# Replace the 'dependencies' line in node-hid/binding.gyp using a pattern match
# rather than a hard-coded line number to stay resilient to upstream changes.
RUN sed -i "/'dependencies':/s/.*/'dependencies': [ 'libusb.gypi\\:libusb', ],/" \
        node_modules/node-hid/binding.gyp \
    && cd node_modules/node-hid && rm -rf build && yarn gypconfigure && yarn gypbuild

# ---------------------------------------------------------------------------
# Stage 2 – runtime
# Slim image that only contains the built application and runtime libraries.
# ---------------------------------------------------------------------------
FROM node:24-bookworm-slim

# jq is used by run.sh to parse /data/options.json
# libusb-1.0-0 and libudev1 are the runtime (not dev) USB libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
        jq \
        libusb-1.0-0 \
        libudev1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/ /app/

COPY run.sh /run.sh
RUN chmod +x /run.sh

# Home Assistant add-on labels (used by the Supervisor)
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="v-berlin" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${BUILD_REF}" \
    org.opencontainers.image.version="${BUILD_VERSION}"

USER node
ENTRYPOINT ["/run.sh"]
