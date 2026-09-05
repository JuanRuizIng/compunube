#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive

log() {
    echo
    echo "======================================"
    echo " $1"
    echo "======================================"
}

install_common_packages() {

    log "Instalando dependencias comunes"

    sudo apt-get update

    sudo apt-get install -y \
        curl \
        wget \
        gpg \
        lsb-release \
        ca-certificates \
        dnsutils
}