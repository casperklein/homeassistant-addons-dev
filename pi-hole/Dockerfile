FROM	pihole/pihole:v5.3.4 as build

ENV	USER="casperklein"
ENV	NAME="homeassistant-pihole-dev"

#ENV	DNSCRYPT="2.0.44"

SHELL	["/bin/bash", "-o", "pipefail", "-c"]

# Update base image packages, install jq and cleanup
RUN	apt-get update && apt-get -y upgrade \
&&	apt-get -y install	jq \
				patch \
&&	rm -rf /var/lib/apt/lists/*

# Disable x-frame-options for Home Assistant Ingress
RUN	sed -i '/"X-Frame-Options"/ s/DENY/SAMEORIGIN/g' /etc/.pihole/advanced/lighttpd.conf*

# Fix Ingress caching problem
RUN	sed -i 's/"mod_expire"/#"mod_expire"/g'	/etc/.pihole/advanced/lighttpd.conf* \
;	sed -i 's/^expire.url/#expire.url/g'	/etc/.pihole/advanced/lighttpd.conf*

# Copy root filesystem
COPY	rootfs /

# Fix chmod/chown errors on startup
# PR 676: Not yet merged in upstream
# https://github.com/pi-hole/docker-pi-hole/pull/676
RUN	wget https://patch-diff.githubusercontent.com/raw/pi-hole/docker-pi-hole/pull/676.diff \
;	patch -i 676.diff bash_functions.sh \
;	apt-get -y purge patch \
;	rm 676.diff

# Unset Pi-hole password for Home Assistant Ingress
#RUN	echo | pihole -a -p

# For network host mode, ServerIP have to be set --> https://github.com/pi-hole/docker-pi-hole/issues/495
# Already fixed upstream. Below should not be neccesary when implementing network host mode at some time.
#RUN	echo 'ServerIP=$(ip route get 1.1.1.1 | cut -d" " -f7)' >> /bash_functions.sh

####################################################################################################
# Install dnscrypt 2.0.44 @ 2020-06-11
#RUN	wget -qO- "https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/$DNSCRYPT/dnscrypt-proxy-linux_arm64-$DNSCRYPT.tar.gz" | tar --strip-component 1 -x linux-arm64/dnscrypt-proxy -z

# Build dnscrypt from source 2020-12-26
FROM	ubuntu:20.04 as dnscrypt

ENV	GIT_USER="dnscrypt"
ENV	GIT_REPO="dnscrypt-proxy"
ENV	GIT_COMMIT="e519dd17bc0574ed4e8939f00547dc457ed698e2"
ENV	GIT_ARCHIVE="https://github.com/$GIT_USER/$GIT_REPO/archive/$GIT_COMMIT.tar.gz"
ENV	DEBIAN_FRONTEND=noninteractive

RUN	apt-get update && apt-get -y upgrade && apt-get -y --no-install-recommends install golang

WORKDIR	/$GIT_REPO
ADD	$GIT_ARCHIVE /
RUN	tar --strip-component 1 -xzvf /$GIT_COMMIT.tar.gz && rm /$GIT_COMMIT.tar.gz
WORKDIR	dnscrypt-proxy
RUN	go build -ldflags="-s -w" -mod vendor
####################################################################################################

# Build final image
FROM	scratch

ARG	BUILD_ARCH
ENV	VERSION="5.3.4.2"
LABEL	io.hass.name="Pi-hole-dev"
LABEL	io.hass.description="Network-wide Ad Blocking"
LABEL	io.hass.arch="${BUILD_ARCH}"
LABEL	io.hass.type="addon"
LABEL	io.hass.version="${VERSION}"

LABEL	image="casperklein/homeassistant-pihole:${VERSION}"
LABEL	maintainer="Casper Klein"
LABEL	url="https://github.com/casperklein/homeassistant-addons/tree/master/pi-hole"

# From base image
ENTRYPOINT [ "/s6-init" ]
ENV	DNSMASQ_USER root
ENV	FTL_CMD no-daemon
ENV	IPv6 True
ENV	PATH /opt/pihole:${PATH}
ENV	PHP_ENV_CONFIG '/etc/lighttpd/conf-enabled/15-fastcgi-php.conf'
ENV	PHP_ERROR_LOG '/var/log/lighttpd/error.log'
ENV	PIHOLE_INSTALL /root/ph_install.sh
ENV	S6_BEHAVIOUR_IF_STAGE2_FAILS 2
ENV	S6_KEEP_ENV 1
ENV	S6_LOGGING 0
ENV	S6OVERLAY_RELEASE https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz
ENV	ServerIP 0.0.0.0
ENV	VERSION v5.3.4
EXPOSE	443
EXPOSE	53 53/udp
EXPOSE	67/udp
EXPOSE	80
HEALTHCHECK CMD dig +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1

COPY	--from=dnscrypt /dnscrypt-proxy/dnscrypt-proxy/dnscrypt-proxy /
COPY	--from=build / /
