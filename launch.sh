#!/bin/bash
set -e
#set -x

# directories
SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
IMAGES_DIR="${SCRIPT_DIR}/images"
CONFIGS_DIR="${SCRIPT_DIR}/configs"

export ENV_NAME=${ENV_NAME:-"baremetal"}
export UNDERCLOUD_NODE_CPU=${UNDERCLOUD_NODE_CPU:-2}
export UNDERCLOUD_NODE_MEMORY=${UNDERCLOUD_NODE_MEMORY:-8192}
export UNDERCLOUD_VOLUME_SIZE=${SLAVE_VOLUME_SIZE:-50}
export OVERCLOUD_NODE_CPU=${OVERCLOUD_NODE_CPU:-1}
export OVERCLOUD_NODE_MEMORY=${OVERCLOUD_NODE_MEMORY:-8192}
export OVERCLOUD_VOLUME_SIZE=${OVERCLOUD_VOLUME_SIZE:-50}
export OS_IMAGE_PATH=${OS_IMAGE_PATH:-"${IMAGES_DIR}/base.qcow2"}
export SSHKEY_ADMIN="${CONFIGS_DIR}/id_rsa_admin"

if [ ! -f "${SSHKEY_ADMIN}" ]; then
    echo "Generating ssh key ${SSHKEY_ADMIN}..."
    ssh-keygen -f "${SSHKEY_ADMIN}" -C admin -q -N ''
fi

if [ ! -f "${OS_IMAGE_PATH}" ]; then
    echo "missing base image... ${OS_IMAGE_PATH}"
    exit 1
fi

echo "Injecting ssh key to root..."
virt-customize -a $OS_IMAGE_PATH \
    --ssh-inject root:file:${SSHKEY_ADMIN}.pub \
    --selinux-relabel

echo "Creating environment..."
dos.py create-env baremetal.yaml
echo "Launching undercloud node..."
dos.py node-start --node-name undercloud $ENV_NAME

echo "SUCESSS! (maybe)"
printf '%20s\n' | tr ' ' -
dos.py show $ENV_NAME
printf '%20s\n' | tr ' ' -
dos.py slave-ip-list $ENV_NAME
