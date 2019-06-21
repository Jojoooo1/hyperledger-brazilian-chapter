#!/bin/bash

set -ev

CHANNEL_NAME=myc
CHAINCODE_NAME_FOLDER=organizacao
CHAINCODE_NAME=organizacao
CONTAINER_IP=10.6.0.1:7052 # set in docker-composer

DIR=$PWD
cd ../../chaincode/$CHAINCODE_NAME_FOLDER
npm install
npm run build
cd $DIR

docker-compose down
docker-compose up -d

sleep 4
# CREATE CHANNEL & JOIN are done by script file executed in CLI container cf. docker-compose.yml "command: /bin/bash -c './script.sh'"

# start chaincode service
gnome-terminal -e "docker exec -it chaincode bash -c 'cd /opt/gopath/src/chaincodedev/chaincode/$CHAINCODE_NAME_FOLDER && CORE_CHAINCODE_ID_NAME=${CHAINCODE_NAME}:0 npm start -- --peer.address grpc://${CONTAINER_IP}'"
sleep 3

# install & instantiate chaincode
gnome-terminal -e "docker exec -it cli bash -c 'peer chaincode install -l node -n $CHAINCODE_NAME -v 0 -p /opt/gopath/src/chaincodedev/chaincode/${CHAINCODE_NAME_FOLDER}'"
sleep 2
docker exec -it cli bash -c "peer chaincode instantiate -n $CHAINCODE_NAME -v 0 -c '{\"Args\":[\"\"]}' -C $CHANNEL_NAME"
sleep 2

# Creates organizacao (json is passed as string)
json='{ \"nome\": \"test\", \"cnpj\": \"test\" }'
docker exec -it cli bash -c "peer chaincode invoke -C myc -n $CHAINCODE_NAME -c '
{\"Args\":[\"createOrganizacao\", \" $json \"]} 
'"

sleep 2

# Gets organizacao created
docker exec -it cli bash -c "peer chaincode query -C myc -n organizacao -c '
{\"Args\":[\"getDataById\", \"test\"]}
'"

sleep 2

# Updates organizacao
json='{ \"cnpj\": \"test\", \"email\": \"email_updated\" }'
docker exec -it cli bash -c "peer chaincode invoke -C myc -n $CHAINCODE_NAME -c '
{\"Args\":[\"updateOrganizacao\", \" $json \"]} 
'"

sleep 2

# Deletes organizacao
docker exec -it cli bash -c "peer chaincode invoke -C myc -n $CHAINCODE_NAME -c '
{\"Args\":[\"deleteOrganizacao\", \"test\"]} 
'"
