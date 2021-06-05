FROM alpine:3.13.5 as base
ARG VERSION
ARG CHECKSUM
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    libressl-dev=3.1.5-r0 \
    sqlite-dev=3.34.1-r0 \
    tcl-dev=8.6.10-r1 \
    zlib-dev=1.2.11-r3 \
    curl=7.77.0-r0 \
    alpine-sdk=1.0-r0 && \
  wget "https://www.fossil-scm.org/home/uv/fossil-src-${VERSION}.tar.gz" -qO fossil-src.tar.gz && \
  echo "${CHECKSUM}  fossil-src.tar.gz" | sha256sum -c && \
  tar --strip-components=1 -xvf fossil-src.tar.gz && \
  echo "**** configure fossil ****" && \
  ls && \
  ./configure \
    --disable-fusefs \
    --json \
    --with-th1-docs \
    --with-th1-hooks \
    --with-tcl-private-stubs=1 \
    --with-tcl=1 && \
  echo "**** make fossil ****" && \
  make && \
  strip fossil && \
  chmod a+rx fossil

FROM ghcr.io/linuxserver/baseimage-alpine:3.13
ARG BUILD_DATE
ARG VERSION
# hadolint ignore=DL3048
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nicholaswilde"
ENV HOME /app
COPY --from=base /fossil /usr/bin/
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    libressl=3.1.5-r0 \
    tcl=8.6.10-r1 && \
  chown -R abc:abc /app && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*
# copy local files
COPY root/ /
EXPOSE 8080
VOLUME /app
