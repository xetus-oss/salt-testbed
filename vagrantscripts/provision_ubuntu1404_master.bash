#!/bin/bash

SALT_DEVELOPMENT="$1"
VM_NAME="$2"
MASTERS_ARE_MINIONS="$3"
SALT_VERSION="$4"

echo "SALT_DEVELOPMENT=${SALT_DEVELOPMENT}"
echo "VM_NAME=${VM_NAME}"
echo "MASTERS_ARE_MINIONS=${MASTERS_ARE_MINIONS}"
echo "SALT_VERSION=${SALT_VERSION}"

# Speed up the apt actions
sed -i 's/archive.ubuntu.com/mirrors.us.kernel.org/g' /etc/apt/sources.list

# Allow the master config to be preserved between vm re-creations
if [ ! -e  /vagrant/config/${VM_NAME}/master.d/default.conf ]
then
  mkdir -p /vagrant/config/${VM_NAME}/master.d
  cp /vagrant/templates/master.default.template /vagrant/config/${VM_NAME}/master.d/default.conf
fi

ETC_PATH="/etc"
if [ "${SALT_DEVELOPMENT}" == "true" ]
then
  ETC_PATH="/virtenv/etc"
fi

# https://github.com/saltstack/salt-bootstrap
if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  curl -L https://bootstrap.saltstack.com -o install_salt.sh
  sudo sh install_salt.sh -M -U -P $SALT_VERSION

  service salt-master stop
  mv /etc/salt/master /etc/salt/master.orig
  cp /vagrant/templates/static_config/master.template /etc/salt/master
else
  apt-get update
  apt-get install -y python-virtualenv libzmq3-dev libzmqpp-dev python-m2crypto libpython-dev python-distutils-extra python-apt
  virtualenv --system-site-packages  /virtenv
  source /virtenv/bin/activate
  pip install pyzmq PyYAML pycrypto msgpack-python jinja2 psutil
  pip install /vagrant/salt-src/
  mkdir -p /virtenv/etc/salt
  cp /vagrant/templates/static_config/master.template /virtenv/etc/salt/master
  sed -i "s+etc+virtenv/etc+g" "/virtenv/etc/salt/master"
fi

# Set the base roots in the master config
sed -i "s/{vmid}/${VM_NAME}/g" "${ETC_PATH}/salt/master"

# Copy the template files if they do not already exist
if [ ! -e /vagrant/salt/states/top.sls ]
then
  cp /vagrant/templates/state_top.sls /vagrant/salt/states/top.sls
fi
if [ ! -e /vagrant/salt/pillar/top.sls ]
then
  cp /vagrant/templates/pillar_top.sls /vagrant/salt/pillar/top.sls
fi
if [ ! -e /vagrant/salt/pillar/defaults.sls ]
then
  cp /vagrant/templates/pillar_defaults.sls /vagrant/salt/pillar/defaults.sls
fi
if [ ! -e /vagrant/salt/pillar/common.sls ]
then
  cp /vagrant/templates/pillar_common.sls /vagrant/salt/pillar/common.sls
fi


if [ "$MASTERS_ARE_MINIONS" == "true" ]
then
  cp /vagrant/templates/static_config/minion.template "${ETC_PATH}/salt/minion"
  sed -i "s/{vmid}/${VM_NAME}/g" "${ETC_PATH}/salt/minion"
  
  if [[ ! -e /vagrant/config/${VM_NAME}/minion.d/masters.conf ]]; then
    mkdir -p /vagrant/config/${VM_NAME}/minion.d
    cp /vagrant/templates/minion.masters.template /vagrant/config/${VM_NAME}/minion.d/masters.conf
  fi

  sed -i "s/master:.*/master: localhost/g" /vagrant/config/${VM_NAME}/minion.d/masters.conf
  sed -i "s/{vmid}/${VM_NAME}/g" /vagrant/config/${VM_NAME}/minion.d/masters.conf
fi

# Install the salt-minion service if desired and expose a stateful
# configuration file
if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  service salt-master start
  if [ "$MASTERS_ARE_MINIONS" == "true" ]
  then
    service salt-minion start
  fi
else
  source /virtenv/bin/activate
  salt-master -c /virtenv/etc/salt -d
  if [ "$MASTERS_ARE_MINIONS" == "true" ]
  then
    salt-minion -c /virtenv/etc/salt -d
  fi
fi

# salt-cloud configuration files, if present, should be symlinked
i=0
cloud_config_dirs[((i++))]="cloud.providers.d"
cloud_config_dirs[((i++))]="cloud.profiles.d"
cloud_config_dirs[((i++))]="cloud.keys.d"

for clouddir in "${cloud_config_dirs[@]}"; do
  mkdir -p /vagrant/config/master/${clouddir}
  ln -s /vagrant/config/master/${clouddir} "${ETC_PATH}/salt/${clouddir}"
done

if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  # In case it's necessary to reboot master outside of vagrant
  sudo cp /vagrant/templates/static_config/rc.local.master.template /etc/rc.local
  echo manual >> /etc/init/salt-master.override
fi