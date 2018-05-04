#!/bin/bash
set -ex

source common.sh

prep_cloudinit() {
    virt-customize -a $OS_IMAGE_PATH \
       --upload ${CONFIGS_DIR}/95-disable-cloud-init-datasource.cfg:/etc/cloud/cloud.cfg.d/
}
# TODO(aschultz): we're asuming DEVOPS ssh key
prep_undercloud_users() {
    if [ ! -f "${OS_IMAGE_PATH}" ]; then
        echo "missing undercloud image..."
        exit 1
    fi
    virt-customize -a $OS_IMAGE_PATH \
        --ssh-inject root:file:${SSHKEY_DEVOPS}.pub \
        --selinux-relabel
}

prep_undercloud_network() {
    virt-customize -a $OS_IMAGE_PATH \
        --firstboot "${CONFIGS_DIR}/configure_base_network.sh"
}

############
# Do Work. #
############

# ssh keys for devops/virtpower
# TODO(aschultz): have these automagically configured
if [ ! -f "${SSHKEY_DEVOPS}" ]; then
  ssh-keygen -f "${SSHKEY_DEVOPS}" -C devops -q -N ''
fi
if [ ! -f "${SSHKEY_VIRTPOWER}" ]; then
  ssh-keygen -f "${SSHKEY_VIRTPOWER}" -C virtpower -q -N ''
  # TODO(aschultz): automagically add this to the local authorized keys
fi


# TODO(aschultz): build iamges rather than downloading them
export OS_IMAGE_PATH="${IMAGES_DIR}/undercloud.qcow2"
fetch_url $CENTOS_IMAGE_URL $OS_IMAGE_PATH

# nuke cloud-init datasource fetch
#prep_cloudinit
# prep the users int eh undercloud image
#prep_undercloud_users
# prep the network to work with predictivte naming and our assumptions around
# public/private network ranges
#prep_undercloud_network

# works
# virt-customize -a images/undercloud.qcow2 --ssh-inject root:file:configs/id_rsa_devops --run-command 'yum remove -y cloud-init*' --root-password password:redhat --firstboot configs/configure_base_network.sh
virt-customize -a $OS_IMAGE_PATH \
  --ssh-inject root:file:${CONFIGS_DIR}/id_rsa_devops \
  --root-password password:redhat \
  --upload ${CONFIGS_DIR}/cloud-init/95-disable-cloud-init-datasource.cfg:/etc/cloud/cloud.cfg.d/
#  --upload ${CONFIGS_DIR}/cloud-init/50-network-fuel-devops-undercloud.cfg:/etc/cloud/cloud.cfg.d/ \
#  --run-command 'yum remove -y cloud-init*' \
#  --firstboot configs/configure_base_network.sh
