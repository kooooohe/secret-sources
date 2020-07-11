#!/bin/bash

set -eu
cd $(dirname $0)

#DB_HOST=127.0.0.1
#DB_PORT=3306
#DB_USER=isucari
#DB_PASS=isucari
#DB_NAME=isucari
#MYSQL_CMD:="mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_NAME}"

NGX_LOG=/tmp/access.log
MYSQL_LOG=/tmp/slow-query.log

GIT_USER_EMAIL="xxx@xxx.com"
GIT_USER_NAME="kooooohe"
setup() {
  echo "start"
  git config --global user.email ${GIT_USER_EMAIL}
	git config --global user.name ${GIT_USER_NAME}
  sudo apt install -y percona-toolkit dstat git unzip snapd
  go get -u github.com/matsuu/kataribe
  kataribe -generate
  go get -u github.com/google/pprof
  echo "finish"
}

kataribe() {
  sudo cat ${NGX_LOG} | kataribe -f ./kataribe.toml
}

pprof() {
  #go tool pprof -http="0.0.0.0:8001" http://0.0.0.0:6060/debug/pprof/profile
  go tool pprof -png -output pprof.png http://localhost:6060/debug/pprof/profile
}

nginx() {
  cat << EOS > nginx.conf
user www-data;
worker_processes auto;
worker_rlimit_nofile 200000;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
error_log  /var/log/nginx/error.log error;
events {
    worker_connections 200000;
}
http {
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        client_max_body_size 20M;
    	location / {
            proxy_set_header Host $http_host;
            proxy_pass http://127.0.0.1:8000;
    	}
    }
    log_format with_time '$remote_addr - $remote_user [$time_local] '
                         '"$request" $status $body_bytes_sent '
                         '"$http_referer" "$http_user_agent" $request_time';
    access_log /var/log/nginx/access.log with_time;
}
EOS
}

mysql_slow_on() {
  sudo mysql -e "set global slow_query_log_file = '${MYSQL_LOG}'; set global long_query_time = 0; set global slow_query_log = ON;"
}
mysql_slow_off() {
  sudo mysql -e "set global slow_query_log = OFF;"
}
 
function_name=${1:-""}
if [ -z ${function_name} ]; then
  echo "set an arg"
  cat << EOS
 _  _              _                      
| || |_____ __ __ | |_ ___   _  _ ___ ___ 
| __ / _ \ V  V / |  _/ _ \ | || (_-</ -_)
|_||_\___/\_/\_/   \__\___/  \_,_/__/\___|

EOS
  cat << EOS
  plase add function name as an argument
  functions:
    setup: install apps
    mysql_slow_on: enable slow query mode
    mysql_slow_of: disable slow query mode
    kataribe: xxx
    pprof: xxx
    nginx: xxx
  refs:
  https://github.com/google/pprof
  https://github.com/matsuu/kataribe
  https://github.com/kooooohe/isucon9-qualify-docker/issues/7
EOS
  exit
fi

$function_name
