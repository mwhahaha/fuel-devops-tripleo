fuel-devops-tripleo
===================

fuel-devops + tripleo = environments


Usage
-----

1) setup [fuel-devops](https://docs.openstack.org/fuel-docs/latest/devdocs/devops.html)
   using master (3.x).  Adjust package names if necessary for RHEL/CentOS.
   You can use sqlite instead of postgres (it's easier). NOTE: You may need
   https://review.openstack.org/#/c/513517/

       export DEVOPS_WORKING_DIR=$(dirname $(readlink -f "$0"))
       export DEVOPS_DB_NAME=$DEVOPS_WORKING_DIR/fuel-devops.db
       export DEVOPS_DB_ENGINE="django.db.backends.sqlite3"
       django-admin.py syncdb --settings=devops.settings
       django-admin.py migrate devops --settings=devops.settings

2) edit go.sh to update the .qcow locations for the undercloud
   NOTE: tested with stock RHEL guest image downloaded from Red Hat

3) run go.sh

4) ansible-playbook -i ansible-inventory undercloud-setup.yml

5) skip to step 4 of the install http://tripleo.org/install/installation/installation.html
   NOTE: techincally if you used the provided undercloud.conf you could just
   skip straight to step 5.

