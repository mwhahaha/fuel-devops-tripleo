fuel-devops-tripleo
===================

fuel-devops + tripleo = environments


Usage
-----

1) setup [fuel-devops](https://docs.fuel-infra.org/fuel-dev/devops.html) using
   master (3.x). Adjust package names if necessary for RHEL/CentOS.
   NOTE: Postgres configuration isn't exactly the same, so YMMV

2) run go.sh

3) make sure to add the configs/id_rsa_virtpower.pub to your user's
   authorized_keys file

4) ssh to undercloud

5) install the undercloud and deploy the overcloud

```
openstack undercloud install

source ~/stackrc

# add swap for overcloud nodes
nova flavor-delete baremetal
nova flavor-create --swap 2048 baremetal auto 4096 38 2
nova flavor-key baremetal set capabilities:boot_option=local

openstack overcloud image upload
openstack baremetal import instackenv.json
openstack baremetal introspection bulk start
#openstack overcloud node introspection


# update dns server
neutron subnet-update $(neutron subnet-list -c id -f value) --dns-nameserver 10.109.0.1

# pull in the swap partition to leverage swap
cat > ~/swap.yaml <<EOF
resource_registry:
  OS::TripleO::AllNodesExtraConfig: /usr/share/openstack-tripleo-heat-templates/extraconfig/all_nodes/swap-partition.yaml
EOF

# deeeplooooy
openstack overcloud deploy --templates /usr/share/openstack-tripleo-heat-templates -e ~/swap.yaml
```
