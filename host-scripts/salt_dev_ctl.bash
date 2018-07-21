#!/bin/bash

function usage(){
  echo "Usage: $0 ACTION"
  echo "Actions:"
  echo "  start-dev-salt"
  echo "  stop-dev-salt"
  echo "  restart-dev-salt"
  echo "  restart-system-salt"
  echo ""
  echo " Note:"
  echo " - All actions start by sourcing the virtual environment."
  echo ""
  echo " - Development salt services are started/stopped based on"
  echo "   the system salt services registered with systemctl"
  echo ""
  echo " - If system salt services are running, they are stopped"
}

SALT_SYSTEMD_SERVICE_DIR=/lib/systemd/system/
function has_salt_minion(){
  [ -e ${SALT_SYSTEMD_SERVICE_DIR}/salt-minion.service ] && \
    return 0 || return 1
}

function has_salt_master(){
  [ -e ${SALT_SYSTEMD_SERVICE_DIR}/salt-master.service ] && \
    return 0 || return 1
}

function has_salt_api(){
  [ -e ${SALT_SYSTEMD_SERVICE_DIR}/salt-api.service ] && \
    return 0 || return 1
}

function system_salt_master_running(){
  systemctl -q is-active salt-master > /dev/null
  return $?
}

function system_salt_api_running(){
  systemctl -q is-active salt-api  > /dev/null
  return $?
}

function system_salt_minion_running(){
  systemctl -q is-active salt-minion  > /dev/null
  return $?
}

function dev_salt_master_running(){
  pgrep -lf /virtenv/bin/salt-master > /dev/null
  return $?
}

function dev_salt_api_running(){
  pgrep -lf /virtenv/bin/salt-api > /dev/null
  return $?
}

function dev_salt_minion_running(){
  pgrep -lf /virtenv/bin/salt-minion > /dev/null
  return $?
}

function test_fn(){
  has_salt_minion
  echo $?
  has_salt_master && has_salt_minion \
    && echo "Nested and YES!" || echo "Nested and NO!"
}

function start_system_salt_services(){
  if has_salt_master
  then
    system_salt_master_running && echo "system salt-master already running" \
      || echo "starting system salt-master" && systemctl start salt-master
  fi

  if has_salt_api
  then
    system_salt_api_running && echo "system salt-api already running" \
      || echo "starting system salt-api" && systemctl start salt-api
  fi

  if has_salt_minion
  then
     system_salt_minion_running && echo "system salt-minion already running" \
      || echo "starting  system salt-minion" && systemctl start salt-minion
  fi
}

function stop_system_salt_services(){
  has_salt_minion && system_salt_minion_running && \
    echo "stopping system salt-minion" && systemctl stop salt-minion 
  has_salt_api && system_salt_api_running &&\
    echo "stopping system salt-api" && systemctl stop salt-api
  has_salt_master && system_salt_master_running &&\
    echo "stopping system salt-master" && systemctl stop salt-master
}

function start_dev_salt_services(){
  if has_salt_master
  then
    dev_salt_master_running && echo "dev salt-master already running" \
      || echo "starting dev salt-master" && salt-master -d
  fi

  if has_salt_api
  then
    dev_salt_api_running && echo "dev salt-api already running" \
      || echo "starting dev salt-api" && salt-api -d
  fi

  if has_salt_minion
  then
    dev_salt_minion_running && echo "dev salt-minion already running" \
      || echo "starting dev salt-minion" && salt-minion -d
  fi
}

function stop_dev_salt_services(){
  dev_salt_minion_running && echo "Killing salt-minion" &&\
    pkill -f /virtenv/bin/salt-minion  
  dev_salt_api_running && echo "Killing salt-api" &&\
    pkill -f /virtenv/bin/salt-api  
  dev_salt_master_running && echo "Killing salt-master" &&\
    pkill -f /virtenv/bin/salt-master  
}

# Ensure we're running as root, give an error otherwise
if [ ! $UID -eq 0 ]
then
  echo "Must be ran by the root user"
  exit 1
fi

# source the virtenv
source /virtenv/bin/activate

case "$1" in

  start-dev-salt)
    stop_system_salt_services
    start_dev_salt_services
    ;;

  stop-dev-salt)
    stop_system_salt_services
    stop_dev_salt_services
    ;;

  restart-dev-salt)
    stop_dev_salt_services
    start_dev_salt_services
    ;;
    
  restart-system-salt)
    stop_dev_salt_services
    start_system_salt_services
    ;;
  *)
    usage
    exit 1
    ;;
esac

exit 0