#!/bin/bash

# ---------------------------------------------------------------------------
# Clear screen
# ---------------------------------------------------------------------------
clear

echo 
echo "# ---------------------------------------------------------------------------"
echo "# Deploy Nodes"
echo "# ---------------------------------------------------------------------------"
    docker stack deploy -c docker/docker-compose-network.yaml -c docker/docker-compose-couch.yaml -c docker/docker-compose-cli.yaml hlf 2>&1
    sleep 5
    docker ps -a
    docker service ls
