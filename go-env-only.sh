#!/bin/bash
# this script launched OOO setup via fuel-devops. There are some hard coded
# assuptions in this script:
# - networks are 10.109.x.x with 10.109.0.x being the "public" network
# - 10.109.0.1 is the virt host
# - undercloud.conf assumes 10.109.1.x is the pxe network ("private")
# - the user running this script has libvirt access
# - x86_64 is the arch used
# - user has the virtpower ssh key added to it's authorized_keys file
# - delorean current triplo undercloud/overcloud is used
set -ex

#TEMPLATE SPECIFIC SETTINGS
export ENV_NAME=${ENV_NAME:-"oooq"}
export UNDERCLOUD_NODE_CPU=${UNDERCLOUD_NODE_CPU:-2}
export UNDERCLOUD_NODE_MEMORY=${UNDERCLOUD_NODE_MEMORY:-8192}
export UNDERCLOUD_VOLUME_SIZE=${SLAVE_VOLUME_SIZE:-50}
export OVERCLOUD_NODE_CPU=${OVERCLOUD_NODE_CPU:-1}
export OVERCLOUD_NODE_MEMORY=${OVERCLOUD_NODE_MEMORY:-8192}
export OVERCLOUD_VOLUME_SIZE=${OVERCLOUD_VOLUME_SIZE:-50}


source common.sh

############
# Do Work. #
############

# TODO(aschultz): build iamges rather than downloading them
export OS_IMAGE_PATH="${IMAGES_DIR}/undercloud.qcow2"

dos.py create-env baremetal.yaml
dos.py node-start --node-name undercloud $ENV_NAME
