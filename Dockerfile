FROM ubuntu:20.04

COPY apt_conf_http /etc/apt/apt.conf.d/

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y \
        software-properties-common \
        build-essential \
        devscripts \
    && rm -rf /var/lib/apt

COPY bin/* /usr/local/bin/
