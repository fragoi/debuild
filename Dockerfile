FROM ubuntu:20.04

LABEL org.opencontainers.image.source=https://github.com/fragoi/debuild-docker
LABEL org.opencontainers.image.description="Build debian packages"
LABEL org.opencontainers.image.licenses="MIT"

COPY apt_conf_http /etc/apt/apt.conf.d/

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        software-properties-common \
        build-essential \
        devscripts \
        openssh-client \
        dput \
    && rm -rf /var/lib/apt

COPY bin/* /usr/local/bin/
