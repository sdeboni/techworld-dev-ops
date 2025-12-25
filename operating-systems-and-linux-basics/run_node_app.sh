#! /bin/bash

function get_pid() {
  echo $(ps aux | awk '/.*node server.js$/ {print $2}')
}

function wait_for_process() {
  pid=$(get_pid)
  if [ -z "$pid" ]
  then
    timeout=5
    while (( $timeout > 0 )) && [ -z "$pid" ] 
    do
      ((timeout--))
      sleep 1
      pid=$(get_pid)
    done 
    if [ -z "$pid" ]
    then
      echo 'node server.js did not start within 5 seconds'
      exit 1
    fi
  fi
  echo $pid
}
function get_port() {
  pid=$1
  echo $(ss -tulpn | grep pid=$pid | awk '{print $5}' | awk -F: '{print $2}')
}

function wait_for_service() {
  pid=$1
  port=$(get_port $pid)
  if [ -n "$port" ]
  then
    echo $port
    exit 0
  fi
  timeout=5
  while (( timeout > 0 )) && [ -z "$port" ]
  do
    (( timeout-- ))
    sleep 1
    port=$(get_port $pid)
  done
  if [ -z "$port" ]
  then
    echo 'service did not start listening within 5 seconds'
    exit 1
  fi
  echo $port
}

echo 'node:' $(node --version)
echo 'npm:' $(npm --version)

getent group | grep servicegroup 
if [ $? -ne 0 ]
then
  groupadd servicegroup
fi
getent passwd | grep myapp
if [ $? -ne 0 ]
then
  useradd -r -s /bin/bash -g servicegroup
fi

service_dir=/opt/my_service
if [ ! -d $service_dir ]
then
   mkdir -p $service_dir
   chgrp $service_dir servicegroup
   chmod 0750 $service_dir
fi

if [ ! -d "$service_dir"/package ]
then
  curl -fOL 'https://node-envvars-artifact.s3.eu-west-2.amazonaws.com/bootcamp-node-envvars-project-1.0.0.tgz' 2> /dev/null
  tar -xzf bootcamp-node-envvars-project-1.0.0.tgz -C "$service_dir"/package
  rm bootcamp-node-envvars-project-1.0.0.tgz
  chgrp -R "$service_dir"/package servicegroup
  chmod -R 0750 "$service_dir"/package
fi

cd /opt/my_service/package
npm install > /dev/null 2>&1
npm audit fix --force > /dev/null 2>&1

if [ -z "$LOG_DIR" ]
then
  read -p "Log Directory: " log_dir
else
  log_dir=$LOG_DIR
fi

if [ -n "$log_dir" ]
then
  if [[ $log_dir =~ ^/ ]]
  then
     LOG_DIR=$log_dir
  else
     LOG_DIR=$(pwd)/$log_dir
  fi
fi
APP_ENV=dev
DB_USER=myuser
DB_PWD=mysecret


if [ ! -d "$LOG_DIR" ]
then
  mkdir -p "$log_dir"
  chgrp servicegroup $log_dir
  chmod 0770 $log_dir
fi

pid=$(get_pid)
if [ -n "$pid" ]
then
  echo "shutting down prev instance '$pid'"
  kill -9 $pid
fi

runuser - myapp -c "export APP_ENV=$APP_ENV; \
export DB_USER=$DB_USER; \
export DB_PWD=$DB_PWD; \
export LOG_DIR=$LOG_DIR; \
nohup node server.js &> /tmp/nohup.out &" &> /dev/null

result=$(wait_for_process)
if [ $? -ne 0 ]
then
  echo "$result"
  ps aux
  exit 1
fi
pid="$result"

result=$(wait_for_service $pid)
if [ $? -ne 0 ]
then
  echo "$result"
else
  echo "process $pid is listening on port $result"
fi 
read -p 'shutdown [Y/n]:' ans
if [[ ! "$ans" =~ [nN] ]]
then
  kill -9 $pid
fi
