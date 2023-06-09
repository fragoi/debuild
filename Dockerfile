FROM ubuntu:20.04

LABEL org.opencontainers.image.source=https://github.com/fragoi/debuild-docker
LABEL org.opencontainers.image.description="Build debian packages"
LABEL org.opencontainers.image.licenses="MIT"

COPY apt_conf_http /etc/apt/apt.conf.d/

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y \
        software-properties-common \
        build-essential \
        devscripts \
    && rm -rf /var/lib/apt

COPY bin/* /usr/local/bin/
