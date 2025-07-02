FROM alpine:latest AS build

RUN apk upgrade --no-cache && apk --no-cache add bash dumb-init dhcp-helper jq docker-cli

# Copy root filesystem
COPY	rootfs /

# Build final image ################################################################################
FROM	scratch

ARG	BUILD_ARCH
ARG	VERSION

LABEL	io.hass.name="Pi-hole-DHCP-helper-dev"
LABEL	io.hass.description="DHCP-helper for Pi-hole"
LABEL	io.hass.arch="${BUILD_ARCH}"
LABEL	io.hass.type="addon"
LABEL	io.hass.version="${VERSION}"

LABEL	image="casperklein/homeassistant-pihole-dhcp-helper-dev:${VERSION}"
LABEL	maintainer="Casper Klein"
LABEL	url="https://github.com/casperklein/homeassistant-addons-dev/tree/master/pi-hole-dhcp-helper"

COPY --from=build / /

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "/usr/bin/run.sh" ]

EXPOSE 67/udp

# https://docs.pi-hole.net/docker/dhcp/#docker-pi-hole-with-a-bridge-networking
# https://discourse.pi-hole.net/t/dhcp-with-docker-compose-and-bridge-networking/17038
