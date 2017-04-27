#!/bin/bash

SALT_DEVELOPMENT="$1"
VM_NAME="$2"
MASTER_IP="$3"
SALT_VERSION="$4"
ETC_PATH="/etc"
if [ "${SALT_DEVELOPMENT}" == "true" ]
then
  ETC_PATH="/virtenv/etc"
fi

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
else
  apt-get update
  apt-get install -y python-virtualenv libzmq3-dev libzmqpp-dev python-m2crypto libpython-dev python-distutils-extra python-apt
  virtualenv --system-site-packages  /virtenv
  source /virtenv/bin/activate
  pip install pyzmq PyYAML pycrypto msgpack-python jinja2 psutil futures tornado

  GENERATE_SALT_SYSPATHS=1 pip install --global-option='--salt-root-dir=/virtenv/' -e /vagrant/salt-src
fi

mkdir -p "${ETC_PATH}/salt/minion.d"
if [ -e "${ETC_PATH}/salt/minion" ]
then
  mv "${ETC_PATH}/salt/minion" "${ETC_PATH}/salt/minion.orig"
fi
echo "${VM_NAME}" > "${ETC_PATH}/salt/minion_id"
cp /vagrant/templates/static_config/minion.template "${ETC_PATH}/salt/minion"
sed -i "s/{vmid}/${VM_NAME}/g" "${ETC_PATH}/salt/minion"

sed -i "s/master:.*/master: ${MASTER_IP}/g" "/vagrant/config/${VM_NAME}/minion.d/masters.conf" 

if [ ! -e "/vagrant/config/${VM_NAME}" ]
then
  mkdir -p "/vagrant/config/${VM_NAME}"
fi

# In case it's necessary to reboot minion outside of vagrant
sudo cp /vagrant/templates/static_config/rc.local.template /etc/rc.local

MINION_START_COMMAND="service salt-minion start"
START_COMMANDS=""
if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  service salt-minion restart
  START_COMMANDS="${START_COMMANDS}\n${MINION_START_COMMAND}"
  echo manual >> /etc/init/salt-minion.override
else
  salt-minion -d
  MINION_START_COMMAND="salt-minion -d"
  START_COMMANDS="${START_COMMANDS}\nsource /virtenv/bin/activate\n\n${MINION_START_COMMAND}"
fi

sed -i "s+# CONFIGURATION BLOCK+${START_COMMANDS}+g" /etc/rc.local
