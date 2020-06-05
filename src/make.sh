#!/bin/bash
set -eu
cd $(dirname $0)
setup() {
  echo "start"
  sudo apt install -y percona-toolkit dstat git unzip snapd
  go get -u github.com/matsuu/kataribe
  kataribe -generate
  go get -u github.com/google/pprof
  echo "finish"
}

kataribe() {
}

pprof() {
}

nginx() {
cat <<EOF > nginx.conf
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
EOF 
}
 
function_name=${1:-""}
if [$function_name = ""];then
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
  refs:
  https://github.com/google/pprof
  https://github.com/matsuu/kataribe
  https://github.com/kooooohe/isucon9-qualify-docker/issues/7
EOS
  exit
fi

$function_name
