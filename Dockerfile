FROM alpine:3.13.0 as base
ARG VERSION=2.14
ARG CHECKSUM=50455c129d3fa8a66d86d732c9bde44471c08cf01fa2b785a03aa68da211e369
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    libressl-dev=3.1.5-r0 \
    sqlite-dev=3.34.1-r0 \
    tcl-dev=8.6.10-r1 \
    zlib-dev=1.2.11-r3 \
    curl=7.74.0-r0 \
    alpine-sdk=1.0-r0 && \
  wget "https://www.fossil-scm.org/index.html/tarball/fossil-src.tar.gz?name=fossil-src&uuid=version-${VERSION}" -O fossil-src.tar.gz && \
  echo "${CHECKSUM}  fossil-src.tar.gz" | sha256sum -c && \
  tar -xvf fossil-src.tar.gz
WORKDIR /fossil-src
RUN \
  echo "**** configure fossil ****" && \
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
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nicholaswilde"
ENV HOME /app
COPY --from=base /fossil-src/fossil /usr/bin/
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    libressl=3.1.5-r0 \
    tcl=8.6.10-r1 && \
  chown -R abc:abc /app && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*
EXPOSE 8080
VOLUME /app
CMD ["/usr/bin/fossil", "server", "--create", "--user", "admin", "/app/repository.fossil"]
