#!/usr/bin/env bash

USAGE="install-service.sh [-c] [BRIDGE INTERFACE]\n\tUsing the '-c' flag will create the bridge with iproute2 utils"

if [ "$#" -eq 0 ]
then
  echo -e "${USAGE}\nNo bridge interface specified. Service not installed."
  exit 1
fi

if [ "$#" -eq 1 ]
then
  CHECKBRIDGE=`ip link show "${1}"`
  if ! [ -z "${CHECKBRIDGE}" ]
  then 
    BRIDGE="${1}"
    cp ./docker.multi /etc/sysconfig/ && \
      cp ./docker@.service /etc/systemd/system/docker@${BRIDGE}.service && \
      ln -s /etc/systemd/system/docker@${BRIDGE}.service /etc/systemd/system/multi-user-target.wants
  fi
else
  echo -e "${USAGE}\nBridge interface does not exist. Bridge must be specified. Service not installed."
  exit 2
fi

if [ "$#" -eq 2 ]
then
  # if the '-c' flag is passed, and there isn't an existing Bridge
  CHECKBRIDGE=`ip link show "${2}"`
  if  [ "${1}" == "-c" ] && [ -z "${CHECKBRIDGE}" ]
  then
  # create the bridge and install the service files
    BRIDGE="${2}"
    ip link add name ${BRIDGE} type bridge
    ip addr add 172.19.0.1/16 dev ${BRIDGE}
    ip link set dev ${BRIDGE} up
    cp ./docker.multi /etc/sysconfig/ && \
      cp ./docker@.service /etc/systemd/system/docker@${BRIDGE}.service && \
      ln -s /etc/systemd/system/docker@${BRIDGE}.service /etc/systemd/system/multi-user-target.wants
  elif [ "${1}" != "-c" ]
  then
    echo -e "${USAGE}\n Cannot create bridge. Use '-c' flag. Service not installed."
    exit 3
  else
    echo -e "${USAGE}\nBridge interface exists. Service not installed."
    exit 4
  fi
fi
SERVICE="docker@${BRIDGE}.serivce"
systemctl daemon-reload
systemctl enable ${SERVICE}

echo -e "${SERVICE} installed."
exit 0
