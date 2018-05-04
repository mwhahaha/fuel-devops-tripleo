#!/bin/bash
set -ex

#TEMPLATE SPECIFIC SETTINGS
# local variables
SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
IMAGES_DIR="${SCRIPT_DIR}/images"
CONFIGS_DIR="${SCRIPT_DIR}/configs"
SSHKEY_DEVOPS="${CONFIGS_DIR}/id_rsa_devops"
SSHKEY_VIRTPOWER="${CONFIGS_DIR}/id_rsa_virtpower"
#CENTOS_IMAGE_URL=http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
CENTOS_IMAGE_URL=http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1802.qcow2
CENTOS_IMAGE_PATH="${IMAGES_DIR}/CentOS-7-x86_64-GenericCloud.qcow2"

if [ ! -d $IMAGES_DIR ]; then
    mkdir -p $IMAGES_DIR
fi

if [ ! -d $CONFIGS_DIR ]; then
    mkdir -p $CONFIGS_DIR
fi

#############
# Functions #
#############

fetch_url() {
    local REMOTE=$1
    local LOCAL=$2

    if [ ! -f "${LOCAL}" ]; then
        wget $REMOTE -O $LOCAL
    fi
}
