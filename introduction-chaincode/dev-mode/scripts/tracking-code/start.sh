#!/bin/bash

set -ev

CHANNEL_NAME=myc
CHAINCODE_NAME_FOLDER=tracking-code
CHAINCODE_NAME=tracking-code
CONTAINER_IP=10.6.0.1:7052 # set in docker-composer

DIR=$PWD
cd ../../chaincode/$CHAINCODE_NAME_FOLDER
npm run build
cd $DIR

docker-compose down
docker-compose up -d

sleep 4
# CREATE CHANNEL & JOIN are done by script file executed in CLI container cf. docker-compose.yml "command: /bin/bash -c './script.sh'"

# start chaincode service
gnome-terminal -x sh -c "docker exec -it chaincode bash -c 'cd /opt/gopath/src/chaincodedev/chaincode/$CHAINCODE_NAME_FOLDER && CORE_CHAINCODE_ID_NAME=${CHAINCODE_NAME}:0 npm start -- --peer.address grpc://10.6.0.1:7052'"
sleep 3

# install & instantiate chaincode
gnome-terminal -x sh -c "docker exec -it cli bash -c 'peer chaincode install -l node -n $CHAINCODE_NAME -v 0 -p /opt/gopath/src/chaincodedev/chaincode/${CHAINCODE_NAME_FOLDER}'"
sleep 2
docker exec -it cli bash -c "peer chaincode instantiate -n $CHAINCODE_NAME -v 0 -c '{\"Args\":[\"\"]}' -C $CHANNEL_NAME"
sleep 2

# execute invoke function
docker exec -it cli bash -c 'peer chaincode invoke -C myc -n tracking-code -c '"'"'
{"Args":["solicitarCodigo", "{\"quantidade\": \"20\", \"embarcador\": \"b2W\"}"]}
'"'"''
sleep 2

# docker exec -it cli bash -c 'peer chaincode query -C myc -n tracking-code -c '"'"'
# {"Args":["getDataById", "CJ265438312QT"]}
# '"'"''

# docker exec -it cli bash -c 'peer chaincode invoke -C myc -n tracking-code -c '"'"'
# {"Args":["usarCodigo", "{\"id\": \"CJ265438312QT\", \"transportador\": \"test\", \"rota\": \"test\", \"servico\": \"test\", \"servico_tracking-code\": \"test\", \"testtdtdtdtdt\": \"fadtdtdtdtdlse\"}"]}
# '"'"''
