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
if [ ! -e  /vagrant/config/salt-master-config ]
then
  mkdir -p /vagrant/config/
  cp /vagrant/templates/salt-master-config /vagrant/config/salt-master-config
fi

# https://github.com/saltstack/salt-bootstrap
if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  curl -L https://bootstrap.saltstack.com -o install_salt.sh
  sudo sh install_salt.sh -M -U -P $SALT_VERSION

  service salt-master stop
  mv /etc/salt/master /etc/salt/master.orig
  ln -s /vagrant/config/salt-master-config /etc/salt/master
else
  apt-get update
  apt-get install -y python-virtualenv libzmq3-dev libzmqpp-dev python-m2crypto libpython-dev python-distutils-extra python-apt
  virtualenv --system-site-packages  /virtenv
  source /virtenv/bin/activate
  pip install pyzmq PyYAML pycrypto msgpack-python jinja2 psutil
  pip install /vagrant/salt-src/
  mkdir -p /virtenv/etc/salt/
  ln -s /vagrant/config/salt-master-config /virtenv/etc/salt/master
fi

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

# Install the salt-minion service if desired and expose a stateful
# configuration file
if [ "${SALT_DEVELOPMENT}" == "false" ]
then
  if [[ "$MASTERS_ARE_MINIONS" -eq "true" ]]; then
    sed -i "s/#master:.\*/master: localhost/g" /etc/salt/minion
    [[ ! -e /vagrant/config/${VM_NAME}.minion.conf ]] && \
    echo "# Enter minion configuration overrides for ${VM_NAME} below" > /vagrant/config/${VM_NAME}.minion.conf
      ln -s /vagrant/config/${VM_NAME}.minion.conf /etc/salt/minion.d/${VM_NAME}.minion.conf
     service salt-minion restart
  fi
  service salt-master start
else
  source /virtenv/bin/activate
  salt-master -c /virtenv/etc/salt -d
fi