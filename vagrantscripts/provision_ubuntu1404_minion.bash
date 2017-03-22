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

# Create an empty config for the minion if one does not already exist
if [ ! -e /vagrant/config/${VM_NAME}/minion ]
then
  cp /vagrant/templates/minion.template /vagrant/config/${VM_NAME}/minion
fi

# https://github.com/saltstack/salt-bootstrap
if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  curl -L https://bootstrap.saltstack.com -o install_salt.sh
  sudo sh install_salt.sh -U -P $SALT_VERSION
  mv /etc/salt/minion /etc/salt/minion.orig
  echo "${VM_NAME}" > /etc/salt/minion_id
  ln -s /vagrant/config/${VM_NAME}/minion /etc/salt/minion
else
  apt-get update
  apt-get install -y python-virtualenv libzmq3-dev libzmqpp-dev python-m2crypto libpython-dev python-distutils-extra python-apt
  virtualenv --system-site-packages  /virtenv
  source /virtenv/bin/activate
  pip install pyzmq PyYAML pycrypto msgpack-python jinja2 psutil

  pip install -e /vagrant/salt-src/
  mkdir -p /virtenv/etc/salt/
  echo "${VM_NAME}" > /virtenv/etc/salt/minion_id
  ln -s /vagrant/config/${VM_NAME}/minion /virtenv/etc/salt/minion
fi

sed -i "s/master:.*/master: ${MASTER_IP}/g" "/vagrant/config/${VM_NAME}/minion"


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