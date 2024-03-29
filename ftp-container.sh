#!/bin/bash
#
# Copyright 2019 is-land
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

usage="USAGE: $0 [start|stop|--help] arg1 arg2 ..."
if [ $# -lt 1 ];
then
  echo $usage
  exit 1
fi

COMMAND=$1
case $COMMAND in
  start)
    start="true"
    shift
    ;;
  stop)
    stop="true"
    shift
    ;;
  --help)
    help="true"
    shift
    ;;
  *)
    echo $usage
    exit 1
    ;;
esac

if [ "${help}" == "true" ];
then
  echo $usage
  echo "Argument             Description"
  echo "--------             -----------"
  echo "--user               Set FTP server user name"
  echo "--password           Set FTP server password"
  echo "--port               Set FTP server port"
  echo "--host               Set host name to remote host the FTP server container"
  echo "--ip                 Set ftp server ip for passive mode"
  exit 1
fi

port="21"
containerName="ftp-benchmark-test"

ARGUMENT_LIST=("user" "password" "port" "host" "ip")

opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)
eval set --$opts

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      user=$2
      shift 2
      ;;
    --password)
      password=$2
      shift 2
      ;;
    --port)
      port=$2
      shift 2
      ;;
    --host)
      host=$2
      shift 2
      ;;
    --ip)
      ip=$2
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z ${user} ]] && [[ "${start}" == "true" ]];
then
  echo 'Please set the --user ${USER_NAME} argument'
  exit 1
fi

if [[ -z ${password} ]] && [[ "${start}" == "true" ]];
then
  echo 'Please set the --password ${PASSWORD} argument'
  exit 1
fi

if [[ -z ${host} ]];
then
  echo 'Please set the --host ${DEPLOY_FTP_SERVER_CONTAINER_HOSTNAME} argument to deploy FTP server container. example: --host host1'
  exit 1
fi

if [[ -z ${ip} ]] && [[ "${start}" == "true" ]];
then
  echo 'Please set the --ip ${DEPLOY_FTP_SERVER_CONTAINER_IP} argument for passive mode. example: --ip 10.1.1.2'
  exit 1
fi

ftpDockerImageName="oharastream/ohara:ftp"
if [[ "${start}" == "true" ]];
then
  echo "Pull FTP server docker image"
  ssh ohara@${host} docker pull $ftpDockerImageName
  echo "Starting FTP server container. user name is $user"
  ssh ohara@${host} docker run -d --name $containerName --env FTP_USER_NAME=$user --env FTP_USER_PASS=$password --env FORCE_PASSIVE_IP=$ip -p $port:21 -p 30000-30100:30000-30100 $ftpDockerImageName
fi

if [[ "${stop}" == "true" ]];
then
  echo "Stoping FTP server container"
  ssh ohara@${host} docker rm -f $containerName
fi
