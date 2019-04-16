SALT_SYSTEMD_SERVICE_DIR=/lib/systemd/system/
SALT_SERVICE_CONF_DIR=/etc/init/
SYSTEMD_ENABLED=""

if [ -x "$(command -v systemctl)" ]
then
  SYSTEMD_ENABLED="true"
fi

function service_exists() {
  file_to_check="$SALT_SERVICE_CONF_DIR/$1.conf"
  if [ $SYSTEMD_ENABLED ]
  then
    file_to_check="${SALT_SYSTEMD_SERVICE_DIR}/$1.service"
  fi
  [ -e "$file_to_check" ] && return 0 || return 1
}

function service_running() {
  result_code=1
  if [ $SYSTEMD_ENABLED ]
  then
    systemctl -q is-active "$1" > /dev/null
    result_code=$?
  else
    result=$(service "$1" status)
    [[ "$result" == *"start/running"* ]] && 
      result_code=0 || result_code=1
  fi

  return $result_code
}

function start_service() {
  result_code=1
  if [ $SYSTEMD_ENABLED ]
  then
    systemctl start "$1"
    result_code=$?
  else
    service "$1" start
    result_code=$?
  fi
  return $result_code
}

function stop_service() {
  result_code=1
  if [ $SYSTEMD_ENABLED ]
  then
    systemctl stop "$1"
    result_code="$?"
  else
    service "$1" stop
    result_code=$?
  fi
  return $result_code
}

function restart_service() {
  result_code=1
  if [ $SYSTEMD_ENABLED ]
  then
    systemctl restart "$1"
    result_code="$?"
  else
    service "$1" restart
    result_code="$?"
  fi
  return $result_code
}