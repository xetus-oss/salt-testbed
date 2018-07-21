#!/bin/bash

function usage(){
  echo "Usage: $0 SALT_SOURCE_DIR"
}

function install_development_sys_dependencies(){
  apt-get install -y\
    python-virtualenv\
    libzmq3-dev\
    libzmqpp-dev\
    python-m2crypto\
    libpython-dev\
    python-distutils-extra\
    python-apt
}

function install_development_pip_depencies(){
  pip install pyzmq PyYAML pycrypto msgpack-python jinja2 psutil futures tornado
}

SALT_SOURCE_DIR=$1

if [ "$SALT_SOURCE_DIR" == "" ]
then
  echo "Error: salt source directory must be specified"
  echo ""
  usage
  exit 1
elif [ "$SALT_SOURCE_DIR" == "-h" ]
then
  usage
  exit
fi

if [ ! -e "$SALT_SOURCE_DIR" ]
then
  echo "Error: salt source dir (${SALT_SOURCE_DIR}) does not exist"
  exit 1
fi


echo ""
echo "Step 1:  Installing system dependencies..."
echo ""

install_development_sys_dependencies

echo ""
echo "Step 2:  Installing dependencies in virtualenv"
echo ""

if [ -e /virtenv/bin/activate ]
then
  echo "Warning: The virtual environment already exists, do you want to continue (Y/N)?"
  read CONTINUE
  if [[ "$CONTINUE" == "Y" || "$CONTINUE" == "y" ]]
  then
    echo -n "Removing existng virtualenv..."
    rm -rf /virtualenv
    echo "done"
  else
    echo "Exiting"
    exit 
  fi
fi

virtualenv --system-site-packages  /virtenv
source /virtenv/bin/activate
install_development_pip_depencies


echo ""
echo "Step 3:  Installing salt from source into virtuenv"
echo ""
pip install --global-option='--salt-root-dir=/virtenv/' -e ${SALT_SOURCE_DIR}

echo ""
echo "Step 4: Symlinking virtenv etc/salt to /etc/salt"
echo ""
mkdir -p /virtenv/etc/
ln -s /etc/salt /virtenv/etc/salt


echo "Reminder, the host-scripts/salt_dev_ctl.bash script can be used to start/stop development services!"
