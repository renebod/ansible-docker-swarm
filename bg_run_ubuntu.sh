#!/bin/bash

NODES=5

case "$1" in
'init')
echo "Intialize Docker Ubuntu"
  IMG='demo_ubuntu'
  docker build -t $IMG .
  NETWORK='mgmt-network'
  docker network inspect $NETWORK || docker network create $NETWORK

  for i in $(eval echo "{1..$NODES}")
  do
    if [ $i == $NODES ]; then
      NAME="ubuntu_manager"
    else
      NAME="ubuntu_$i"
    fi
    echo "Starting Container $NAME, based on $IMG"
    docker rm -f $NAME

    docker run --detach \
        --hostname $NAME.example.com \
        --name $NAME \
        --publish 808$i:8080 \
        --volume $PWD:/ansible \
        --privileged \
        --network=$NETWORK \
        --restart always \
        $IMG
  done
;;
'config')
echo "Config Management"
  docker exec -it ubuntu_manager ansible-playbook -i ansible/hosts \
      ansible/configure_ansible_docker.yml -f $NODES $2
;;
'swarm')
echo "Starting Swarm"
  docker exec -it ubuntu_manager ansible-playbook -i ansible/hosts \
      ansible/swarm.yml $2
  docker exec -it ubuntu_1 docker node ls
;;
'portainer')
echo "Deploying Portainer to Swarm"
  docker exec -it ubuntu_1 docker service create --name portainer portainer/portainer
;;
'nginx')
echo "Deploying NGINX to Swarm"
  docker exec -it ubuntu_1 docker service create --replicas 4 -p 8080:8080 --name web nginx
;;
'firefox')
  docker run -e DISPLAY -v $HOME/.Xauthority:/home/developer/.Xauthority --net=host $IMG /bin/bash
;;
*)
echo "Please add command: $0 [init|config|swarm]"
;;
esac
