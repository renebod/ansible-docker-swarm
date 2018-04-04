#!/bin/bash

NODES=5

if [ -z "$1" ]; then
  docker build -t demo_ubuntu .
  IMG='demo_ubuntu'

  for i in $(eval echo "{1..$NODES}")
  do
    if [ $i == $NODES ]; then
      NAME="ubuntu_manager"
    else
      NAME="ubuntu_$i"
    fi
    echo "Starting Container $NAME, SSH on $PORT"
    docker rm -f $NAME

    docker run --detach \
        --hostname $NAME.example.com \
        --name $NAME \
        --volume $PWD:/ansible \
        --network=mgmt-network \
        --restart always \
        $IMG
  done
fi

docker exec -it ubuntu_manager ansible-playbook -i ansible/hosts \
    ansible/configure_ansible_docker.yml -f $NODES
