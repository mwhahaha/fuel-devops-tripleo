fuel-devops-tripleo
===================

fuel-devops + tripleo = environments


Usage
-----

1) setup [fuel-devops](https://docs.openstack.org/fuel-docs/latest/devdocs/devops.html) using
   master (3.x). Adjust package names if necessary for RHEL/CentOS.
   NOTE: You can use sqlite on CentOS just fine. Postgres configuration isn't exactly the same, so YMMV

   HINT:
   export WORKING_DIR=~/fuel-devops/
   export DEVOPS_DB_NAME=$WORKING_DIR/fuel-devops
   export DEVOPS_DB_ENGINE="django.db.backends.sqlite3"

2) Grab your favorite cloud .qcow2 image and put it in images/base.qcow2

3) run launch.sh

4) ssh to undercloud

5) do stuff
