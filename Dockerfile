# Set global vars
ARG REL=3.18
ARG MINOR=2
ARG ARCH=x86_64

#Use alpine as base-build image to pull alpine minirootfs https://dl-cdn.alpinelinux.org/alpine/v${REL}/releases/${ARCH}/alpine-minirootfs-${REL}.0-${ARCH}.tar.gz and create rootfs.
FROM alpine:${REL} as rootfs-stage

# Set local vars for rootfs-stage
ARG REL \
MINOR \
ARCH \
ROOTFOLDER="/root-out" \
S6_OVERLAY_URL="https://github.com/just-containers/s6-overlay/releases/download" \
#S6_OVERLAY_VERSION="3.1.2.1" \
S6_OVERLAY_VERSION="3.1.5.0" \
OVERLAY_ARCH="x86_64" \
TZ="Europe\Amsterdam"
ENV REL="${REL}" \
ARCH="${ARCH}"

# install buildtime packages, download s6, Alpine minirootfs.
RUN \
 apk add --no-cache \
        bash \
        curl \
        tzdata \
        xz \
		tar && \
echo "Create root-out folder" && \
	mkdir ${ROOTFOLDER} && \
echo "download s6 noarch" && \
	curl -o /tmp/s6-overlay-noarch.tar.xz -L ${S6_OVERLAY_URL}/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz && \
	tar -C ${ROOTFOLDER}  -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
echo "download s6 x86-64" && \
	curl -o /tmp/s6-overlay-${OVERLAY_ARCH}.tar.xz -L ${S6_OVERLAY_URL}/v${S6_OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.xz && \
	tar -C ${ROOTFOLDER}  -Jxpf /tmp/s6-overlay-${OVERLAY_ARCH}.tar.xz && \
echo "download s6 symlinks for s6-overlay v2 compatibilty" && \
	curl -o /tmp/s6-overlay-symlinks-noarch.tar.xz -L ${S6_OVERLAY_URL}/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz && \
	tar -C ${ROOTFOLDER}  -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
echo "download s6 syslogd" && \
	curl -o /tmp/syslogd-overlay-noarch.tar.xz -L ${S6_OVERLAY_URL}/v${S6_OVERLAY_VERSION}/syslogd-overlay-noarch.tar.xz && \
	tar -C ${ROOTFOLDER}  -Jxpf /tmp/syslogd-overlay-noarch.tar.xz && \
echo "Download fresh copy of alpine-minirootfs ${REL} - ${ARCH}" && \
	curl -o /tmp/rootfs.tar.gz -L https://dl-cdn.alpinelinux.org/alpine/v${REL}/releases/${ARCH}/alpine-minirootfs-${REL}.${MINOR}-${ARCH}.tar.gz && \
	tar -zxvf /tmp/rootfs.tar.gz -C ${ROOTFOLDER} && \
	sed -i -e 's/^root::/root:!:/' ${ROOTFOLDER}/etc/shadow

# Runtime stage: Create actual base image from scratch
FROM scratch
COPY --from=rootfs-stage /root-out/ /

#labels:
LABEL build_version="Alpine-baseimage-from-scratch version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL MAINTAINER="thies88, Thnx to: sparkyballs,TheLamer"

#runtime vars
ARG REL \
ARCH \
BUILD_DATE \
VERSION 

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
REL="v${REL}" \
ARCH="${ARCH}" \
TZ="${TZ}" \
LANGUAGE="en_US.UTF-8" \
LANG="en_US.UTF-8" \
HOME="/root" \
TERM="xterm" \
# 2: Stop by sending a termination signal to the supervision tree.
S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
# The maximum time (in milliseconds) the services could take to bring up before proceding to CMD executing.
S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0"

#Add some repo's
RUN \
#echo "**** install build packages ****" && \
# apk add --no-cache --virtual=build-dependencies \
#	curl && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	alpine-release \
	bash \
	ca-certificates \
	coreutils \
	curl \
	jq \
	procps \
	shadow \
	tzdata && \
 echo "**** create abc user and make our folders ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 mkdir -p \
	/app \
	/config \
	/defaults && \
 echo "**** cleanup ****" && \
# apk del --purge \
#	build-dependencies && \
 rm -rf \
	/tmp/* /usr/share/terminfo/* && \
echo "save packages list to /package-list/package-list.txt to later extract this and add to github" && \
mkdir -p /package-list && \
	apk info -vv|sort > /package-list/package-list.txt

# add local files
COPY root/ /

# Fix some permissions for copied files
RUN \
 chmod -R 500 /etc/cont-init.d

ENTRYPOINT ["/init"]
