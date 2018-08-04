#
# MACHINE_NAME must be set before this script is called!
# It is typically set by the vagrant script
#
# ROLE_TYPE

HOST_DATA_ROOT=/vagrant/host-data
NEW_HOST=""

if [ ! -e ${HOST_DATA_ROOT}/${MACHINE_NAME} ]
then
  mkdir -p ${HOST_DATA_ROOT}/${MACHINE_NAME}
  NEW_HOST="true"
fi

#
# Setup the template etc directory, creating if
# if necessary
#
if [ $NEW_HOST ]
then
  mv /etc/salt ${HOST_DATA_ROOT}/${MACHINE_NAME}/etc-salt/
fi
rm -rf /etc/salt
ln -s ${HOST_DATA_ROOT}/${MACHINE_NAME}/etc-salt/ /etc/salt 

#
# (Masters Only): Create a template salt-srv directory if
# done does not already exist
#
if [ $IS_MASTER == "true" ]
then
  if $NEW_HOST
  then
    mkdir -p ${HOST_DATA_ROOT}/${MACHINE_NAME}/srv-salt
  fi

  rm -rf /srv/salt
  ln -s ${HOST_DATA_ROOT}/${MACHINE_NAME}/srv-salt/ /srv/salt 
fi

if [ $IS_MASTER == "true" ]
then
  systemctl restart salt-master
fi

systemctl restart salt-minion