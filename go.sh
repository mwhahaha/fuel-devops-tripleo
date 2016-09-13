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
set -e

#TEMPLATE SPECIFIC SETTINGS
export ENV_NAME=${ENV_NAME:-"oooq"}
export UNDERCLOUD_NODE_CPU=${UNDERCLOUD_NODE_CPU:-2}
export UNDERCLOUD_NODE_MEMORY=${UNDERCLOUD_NODE_MEMORY:-4096}
export UNDERCLOUD_VOLUME_SIZE=${SLAVE_VOLUME_SIZE:-50}
export OVERCLOUD_NODE_CPU=${OVERCLOUD_NODE_CPU:-1}
export OVERCLOUD_NODE_MEMORY=${OVERCLOUD_NODE_MEMORY:-4096}
export OVERCLOUD_VOLUME_SIZE=${OVERCLOUD_VOLUME_SIZE:-50}

# local variables
SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
IMAGES_DIR="${SCRIPT_DIR}/images"
CONFIGS_DIR="${SCRIPT_DIR}/configs"
SSHKEY_DEVOPS="${CONFIGS_DIR}/id_rsa_devops"
SSHKEY_VIRTPOWER="${CONFIGS_DIR}/id_rsa_virtpower"
CENTOS_IMAGE_URL=http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
CENTOS_IMAGE_PATH="${IMAGES_DIR}/CentOS-7-x86_64-GenericCloud.qcow2"
UNDERCLOUD_IMAGE_URL=http://images.rdoproject.org/master/delorean/current-tripleo/stable/undercloud.qcow2
OVERCLOUD_IMAGE_URL=http://images.rdoproject.org/master/delorean/current-tripleo/stable/overcloud-full.tar


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

# TODO(aschultz): we're asuming DEVOPS ssh key
prep_undercloud_users() {
    local USER=$1
    local GROUP=$2
    local HOME_DIR=$3
    if [ ! -f "${UNDERCLOUD_IMAGE_PATH}" ]; then
        echo "missing undercloud image..."
        exit 1
    fi
    virt-customize -a $UNDERCLOUD_IMAGE_PATH \
        --mkdir "${HOME_DIR}/.ssh" \
        --upload "${SSHKEY_DEVOPS}.pub:${HOME_DIR}/.ssh/authorized_keys" \
        --run-command "chown -R ${USER}:${GROUP} ${HOME_DIR}/.ssh/" \
        --run-command "chmod 0700 ${HOME_DIR}/.ssh/" \
        --run-command "chmod 0600 ${HOME_DIR}/.ssh/authorized_keys" \
        --selinux-relabel
}

prep_undercloud_network() {
    virt-customize -a $UNDERCLOUD_IMAGE_PATH \
        --firstboot "${CONFIGS_DIR}/configure_base_network.sh"
}

get_host_ip() {
   #PRIVATE_NETWORK=$(dos.py net-list $ENV_NAME | grep private | awk '{print $2}')
   #TODO(aschultz):fix this to find the right ip
   echo '10.109.0.1'
}

generate_instackenv() {
    local NODES
    local JSON
    # TODO(aschultz) cheating
    local ARCH="x86_64"
    local PM_IPADDR="$(get_host_ip)"
    local PM_USER="$(whoami)"
    local PM_KEY="$(cat ${SSHKEY_VIRTPOWER}|sed 's,$,\\n,'|tr -d '\n')"

    NODES=$(virsh list --all | grep "${ENV_NAME}_node" | awk '{ print $2 }')
    JSON=$(jq "." <<EOF
{
    "nodes":[],
    "arch":"${ARCH}",
    "host-ip":"${PM_IPADDR}",
    "power_manager":"nova.virt.baremetal.virtual_power_driver.VirtualPowerManager",
    "seed-ip":"",
    "ssh-key":"${PM_KEY}",
    "ssh-user":"${PM_USER}"
}
EOF
)

    for NODE in $NODES; do
        XML="$(virsh dumpxml $NODE)"
        MACS=$(echo "${XML}" | grep 'mac address' | cut -d "'" -f 2)
        JSON=$(jq \
            --arg macs "${MACS}" \
            ".nodes=(.nodes + [{ pm_addr:\"${PM_IPADDR}\", pm_password:\"${PM_KEY}\", pm_type:\"pxe_ssh\", pm_user:\"${PM_USER}\", cpu:${OVERCLOUD_NODE_CPU}, memory:${OVERCLOUD_NODE_MEMORY}, disk:${OVERCLOUD_VOLUME_SIZE}, arch:\"${ARCH}\", mac:\$macs | split (\"\n\")}])" \
            <<< $JSON)
    done
    jq . <<< $JSON > "${SCRIPTS_DIR}/instackenv.json"
}

wait_for_host() {
    local IP=$1
    local TIMEOUT=${2:-30}
    local COUNTER=1
    while true;
    do
        ping -c 1 $IP >/dev/null
        if [ $? -eq 0 ]; then
            return 0
        elif [ $COUNTER -eq $TIMEOUT ]; then
            return 1
        fi
        let COUNTER=COUNTER+1
    done
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
export UNDERCLOUD_IMAGE_PATH="${IMAGES_DIR}/undercloud.qcow2"
fetch_url $UNDERCLOUD_IMAGE_URL $UNDERCLOUD_IMAGE_PATH

#fetch_url $CENTOS_IMAGE_URL $CENTOS_IMAGE_PATH
#export OVERCLOUD_IMAGE_PATH="${SCRIPT_DIR}/overcloud-full.tar"
#fetch_url $OVERCLOUD_IMAGE_URL $OVERCLOUD_IMAGE_PATH

# prep the users int eh undercloud image
prep_undercloud_users 'root' 'root' '/root'
prep_undercloud_users 'stack' 'stack' '/home/stack'
# prep the network to work with predictivte naming and our assumptions around
# public/private network ranges
prep_undercloud_network

dos.py create-env ooo-template.yaml
dos.py node-start --node-name undercloud $ENV_NAME

generate_instackenv

# TODO(aschultz): ip address and exception handling
set +e
wait_for_host 10.109.0.2
if [ $? -eq 0 ]; then
scp -i ${SSHKEY_DEVOPS} "${CONFIGS_DIR}/undercloud.conf" stack@10.109.0.2:
scp -i ${SSHKEY_DEVOPS} "${CONFIGS_DIR}/instackenv.json" stack@10.109.0.2:
cat <<EOF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
You can now proceed with the undercloud setup...
ssh -i ${SSHKEY_DEVOPS} stack@10.109.0.2
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOF

else
# TODO(aschultz): automate this better
cat <<EOF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Don't forget to copy config/undercloud.conf and instackenv.jsona to the
undercloud before setting up the undercloud.
scp -i ${SSHKEY_DEVOPS} configs/undercloud.conf stack@10.109.0.2:
scp -i ${SSHKEY_DEVOPS} instackenv.json stack@10.109.0.2:
ssh -i ${SSHKEY_DEVOPS} stack@10.109.0.2
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOF

fi
