#!/bin/bash
set -e

#TEMPLATE SPECIFIC SETTINGS
export ENV_NAME=${ENV_NAME:-"oooq"}
# local variables
SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
IMAGES_DIR="${SCRIPT_DIR}/images"
CONFIGS_DIR="${SCRIPT_DIR}/configs"
OVERCLOUD_NODE_CPU=${OVERCLOUD_NODE_CPU:-1}
OVERCLOUD_NODE_MEMORY=${OVERCLOUD_NODE_MEMORY:-8192}
OVERCLOUD_VOLUME_SIZE=${OVERCLOUD_VOLUME_SIZE:-50}
SSHKEY_DEVOPS="${CONFIGS_DIR}/id_rsa_devops"
SSHKEY_VIRTPOWER="${CONFIGS_DIR}/id_rsa_virtpower"
PM_USER=${PM_PASSWORD:-admin}
PM_PASSWORD=${PM_PASSWORD:-tripleo}
PM_PORT_BASE=${PM_PORT_BASE:-6200}


#############
# Functions #
#############


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
    local PM_KEY="$(cat ${SSHKEY_VIRTPOWER}|sed 's,$,\\n,'|tr -d '\n')"

    NODES=$(sudo virsh list --all | grep "${ENV_NAME}_node" | awk '{ print $2 }')
    JSON=$(jq "." <<EOF
{
    "nodes":[],
    "arch":"${ARCH}",
    "host-ip":"${PM_IPADDR}",
    "seed-ip":""
}
EOF
)

    COUNT=0
    for NODE in $NODES; do
        XML="$(sudo virsh dumpxml $NODE)"
        MACS=$(echo "${XML}" | grep 'mac address' | cut -d "'" -f 2)
        PM_PORT=$(($PM_PORT_BASE + $COUNT))
        JSON=$(jq \
            --arg macs "${MACS}" \
            ".nodes=(.nodes + [{ pm_addr:\"${PM_IPADDR}\", pm_password:\"${PM_PASSWORD}\", pm_type:\"pxe_ipmitool\", pm_user:\"${PM_USER}\", pm_port:\"${PM_PORT}\", cpu:${OVERCLOUD_NODE_CPU}, memory:${OVERCLOUD_NODE_MEMORY}, disk:${OVERCLOUD_VOLUME_SIZE}, arch:\"${ARCH}\", mac:\$macs | split (\"\n\")}])" \
            <<< $JSON)
        COUNT=$(($COUNT + 1))
    done
    jq . <<< $JSON > "${CONFIGS_DIR}/instackenv.json"
}

#######

# ssh keys for devops/virtpower
# TODO(aschultz): have these automagically configured
if [ ! -f "${SSHKEY_DEVOPS}" ]; then
  ssh-keygen -f "${SSHKEY_DEVOPS}" -C devops -q -N ''
fi
if [ ! -f "${SSHKEY_VIRTPOWER}" ]; then
  ssh-keygen -f "${SSHKEY_VIRTPOWER}" -C virtpower -q -N ''
  # TODO(aschultz): automagically add this to the local authorized keys
fi



generate_instackenv

