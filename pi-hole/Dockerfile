# Customize upstream image #########################################################################
FROM	pihole/pihole:2025.03.0 AS pihole

ARG	YQ_VERSION=v4.45.1
ARG	SV_VERSION=0.1

SHELL	["/bin/bash", "-e", "-o", "pipefail", "-c"]

# Check if build args are not empty ################################################################
ARG	BUILD_ARCH
ARG	VERSION
RUN	[ -z "$BUILD_ARCH" ] && echo "Error: Build argument 'BUILD_ARCH' is missing" && exit 1 || true
RUN	[ -z "$VERSION" ] && echo "Error: Build argument 'VERSION' is missing" && exit 1 || true

# Update base image packages
RUN	apk upgrade --no-cache \
&&	apk add --no-cache dumb-init nginx

# Copy root filesystem
COPY	rootfs /

# Install yq
RUN <<EOF
	if [ "$BUILD_ARCH" == "armhf" ]; then
		BUILD_ARCH=arm
	fi
	curl -sSLf -o /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_$BUILD_ARCH"
	chmod +x /usr/bin/yq
EOF

# Install supervisor.sh
RUN <<"EOF"
	curl -sSLf -o /usr/bin/supervisor.sh "https://raw.githubusercontent.com/casperklein/supervisor.sh/refs/tags/$SV_VERSION/supervisor.sh"
	chmod +x /usr/bin/supervisor.sh
	supervisor.sh --config /etc/supervisor.yaml convert
EOF

# todo
# todo https://github.com/pi-hole/FTL/issues/2215
# Disable x-frame-options for Home Assistant Ingress
# RUN	sedfile -i '/"X-Frame-Options"/ s/DENY/SAMEORIGIN/g' /etc/.pihole/advanced/pihole-admin.conf

# Better Fix at runtime (existing setups)? --> if so, then remove from custom pi-hole.toml
# sed '/X-Frame-Options: DENY/d' pihole.toml

# Check if defaults have changed
RUN <<"EOF"
	CHECKSUM=$(curl -sSLf https://raw.githubusercontent.com/pi-hole/FTL/refs/heads/master/src/config/config.c | grep 'webserver.headers.d.json' | sha1sum)
	if [ "${CHECKSUM%% *}" != "7b3d05f2871939e2d3e4036d473fa03b5c6eece4" ]; then
		echo "Default webserver headers config has changed. Check: https://raw.githubusercontent.com/pi-hole/FTL/refs/heads/master/src/config/config.c"
		echo
		exit 1
	fi
EOF

# Remove docker-pi-hole update instructions
RUN	sedfile -i 's|To install updates, <a href="https://github.com/pi-hole/docker-pi-hole#upgrading-persistence-and-customizations" rel="noopener" target="_blank">replace this old container with a fresh upgraded image</a>.||' /var/www/html/admin/scripts/js/footer.js

# Remove no longer needed dependencies (saves 10MB)
RUN	rm /usr/bin/sedfile /usr/bin/yq
RUN	rm /etc/nginx/http.d/default.conf

# Build dnscrypt-proxy from source #################################################################
FROM	golang:bookworm AS dnscrypt

ENV	GIT_USER="dnscrypt"
ENV	GIT_REPO="dnscrypt-proxy"
ENV	GIT_COMMIT="2.1.7"
ENV	GIT_ARCHIVE="https://github.com/$GIT_USER/$GIT_REPO/archive/$GIT_COMMIT.tar.gz"
ENV	DEBIAN_FRONTEND=noninteractive

RUN	apt-get update && apt-get -y upgrade

WORKDIR	/$GIT_REPO
ADD	$GIT_ARCHIVE /
RUN	tar --strip-component 1 -xzvf /$GIT_COMMIT.tar.gz && rm /$GIT_COMMIT.tar.gz
WORKDIR	/$GIT_REPO/dnscrypt-proxy

# Compile with static linking (including all library code in the binary); needed for alpine image
# Otherwise --> /dnscrypt-proxy: cannot execute: required file not found
ENV	CGO_ENABLED=0

# Builds a Go binary without symbol tables and debugging information, reducing the file size.
RUN	go build -ldflags="-s -w" -mod vendor

# Build final image ################################################################################
FROM	scratch

ARG	BUILD_ARCH
ARG	VERSION

LABEL	io.hass.name="Pi-hole-dev"
LABEL	io.hass.description="Network-wide Ad Blocking"
LABEL	io.hass.arch="${BUILD_ARCH}"
LABEL	io.hass.type="addon"
LABEL	io.hass.version="${VERSION}"

LABEL	image="casperklein/homeassistant-pihole-dev:${VERSION}"
LABEL	maintainer="Casper Klein"
LABEL	url="https://github.com/casperklein/homeassistant-addons-dev/tree/master/pi-hole"

# TODO
# ENV	FTLCONF_webserver_paths_prefix=""
# ENV	FTLCONF_webserver_paths_webhome=""

# Disable authentication. Done via Home Assistant ingress
ENV	FTLCONF_webserver_api_password=""
# TODO Try WEBPASSWORD_FILE when released, to avoid build check warning: SecretsUsedInArgOrEnv - https://docs.docker.com/go/dockerfile/rule/secrets-used-in-arg-or-env/
# ENV	WEBPASSWORD_FILE="/etc/WEBPASSWORD_FILE"

# Disable DHCP
ENV	FTLCONF_dhcp_active="false"

COPY	--from=dnscrypt /dnscrypt-proxy/dnscrypt-proxy/dnscrypt-proxy /
COPY	--from=pihole / /

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD	[ "/usr/bin/supervisor.sh", "--config", "/etc/supervisor.yaml.sh" ]

# TODO
# Not yet in base image: https://github.com/pi-hole/docker-pi-hole/pull/1768
EXPOSE	123/udp

# From base image
# docker-image-options pihole/pihole:latest | sort | grep -v LABEL

# ENTRYPOINT ["start.sh"]
ENV DNSMASQ_USER="pihole"
ENV FTL_CMD="no-daemon"
EXPOSE 443/tcp
EXPOSE 53/tcp
EXPOSE 53/udp
# EXPOSE 67/udp
EXPOSE 80/tcp
HEALTHCHECK CMD dig +short +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1
WORKDIR /
