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
      ansible/swarm.yml
  docker exec -it ubuntu_1 docker node ls
;;
'portainer')
CMD="docker service create \
  --name portainer \
  --publish 9000:9000 \
  --privileged \
  --constraint 'node.role == manager' \
  --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
  portainer/portainer \
  -H unix:///var/run/docker.sock"

CMD2=docker run -d -p 9000:9000 portainer/portainer -H tcp://localhost:2375

docker exec -it ubuntu_1 $CMD
#open -a /Applications/Firefox.app -g http://news.google.com
;;
*)
echo "Please add command: $0 [init|config|swarm]"
;;
esac
