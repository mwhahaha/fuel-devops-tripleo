export OS_IMAGE_PATH=`pwd`/images/rhel-guest-image-8.0-1823.x86_64.qcow2
DRIVER_USE_HUGEPAGES=true ENV_NAME=rhel8 bash launch.sh
ENV_NAME=rhel8 ./buildjson.sh && echo "config/instack.json has been generated"
echo "run: scp configs/instackenv.json root@10.109.0.2:"

