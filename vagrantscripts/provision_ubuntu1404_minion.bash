#!/bin/bash

SALT_DEVELOPMENT="$1"
VM_NAME="$2"
MASTER_IP="$3"
SALT_VERSION="$4"

echo "SALT_DEVELOPMENT=${SALT_DEVELOPMENT}"
echo "VM_NAME=${VM_NAME}"
echo "MASTER_IP=${MASTER_IP}"
echo "SALT_VERSION=${SALT_VERSION}"

# Speed up apt operations
sed -i 's/archive.ubuntu.com/mirrors.us.kernel.org/g' /etc/apt/sources.list

mkdir -p /vagrant/config/${VM_NAME}/minion.d

# Create an empty config for the minion if one does not already exist
if [ ! -e /vagrant/config/${VM_NAME}/minion.d/masters.conf ]
then
  cp /vagrant/templates/minion.masters.template /vagrant/config/${VM_NAME}/minion.d/masters.conf
fi

# https://github.com/saltstack/salt-bootstrap
if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  curl -L https://bootstrap.saltstack.com -o install_salt.sh
  sudo sh install_salt.sh -U -P $SALT_VERSION
  mkdir -p /etc/salt/minion.d
  mv /etc/salt/minion /etc/salt/minion.orig
  echo "${VM_NAME}" > /etc/salt/minion_id
  cp /vagrant/templates/static_config/minion.template /etc/salt/minion
  sed -i "s/{vmid}/${VM_NAME}/g" "/etc/salt/minion"
else
  apt-get update
  apt-get install -y python-virtualenv libzmq3-dev libzmqpp-dev python-m2crypto libpython-dev python-distutils-extra python-apt
  virtualenv --system-site-packages  /virtenv
  source /virtenv/bin/activate
  pip install pyzmq PyYAML pycrypto msgpack-python jinja2 psutil

  pip install -e /vagrant/salt-src/
  mkdir -p /virtenv/etc/salt/
  echo "${VM_NAME}" > /virtenv/etc/salt/minion_id
  cp /vagrant/templates/static_config/minion.template /virtenv/etc/salt/minion
  sed -i "s/{vmid}/${VM_NAME}/g" "/virtenv/etc/salt/minion"
  sed -i "s+etc+virtenv/etc+g" "/virtenv/etc/salt/minion"
fi

sed -i "s/master:.*/master: ${MASTER_IP}/g" "/vagrant/config/${VM_NAME}/minion.d/masters.conf" 

if [ ! -e "/vagrant/config/${VM_NAME}" ]
then
  mkdir -p "/vagrant/config/${VM_NAME}"
fi

if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  service salt-minion restart
else
  salt-minion -c /virtenv/etc/salt -d
fi

if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  # In case it's necessary to reboot minion outside of vagrant
  sudo cp /vagrant/templates/static_config/rc.local.minion.template /etc/rc.local
  echo manual >> /etc/init/salt-minion.override
fi