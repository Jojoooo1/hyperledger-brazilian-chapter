export COMPOSE_PROJECT_NAME=net
export IMAGE_TAG=latest
export CORE_PEER_TLS_ENABLED=true
export CA_TLS_ENABLED=true

# ----------------------
# for keepings same utils file when using multiple host
# 1 = Instantiating chaincode host
INSTANTIATING_HOST=true
COMPOSE_FILE=docker-compose-cli.yaml
COMPOSE_FILE_RAFT=docker-compose-etcdraft2.yaml

LANGUAGE=node
VERSION=1.0.0
GO_PATH=/opt/gopath/src/
CHAINECODE_PATH="${GO_PATH}github.com/chaincode/" # defined in volume

CHANNEL_NAME=mychannel

CHAINCODE_NAME=('organizacao')
CHAINCODE_NAME_WITH_PRIVATE_COLLECTION=()
CHAINCODE_POLICY=('"AND ('"'"'Org1MSP.peer'"'"','"'"'Org2MSP.peer'"'"')"')
CHAINCODE_POLICY_PRIVATE_COLLECTION=()

export DOMAIN=example.com
export ORGANIZATION_NAME=(Org1MSP Org2MSP)
export ORGANIZATION_MSPID=(Org1MSP Org2MSP)
export ORGANIZATION_DOMAIN=(org1.example.com org2.example.com)
# dont forget to modify template count in crypto-config
ORGANIZATION_PEER_NUMBER=(1 1)
ORGANIZATION_PEER_STARTING_PORT=(7051 9051) # PORT START NUMBER

ORDERER_TYPE="raft"
ORDERER_NAME="orderer"
ORDERER_DOMAIN="orderer.example.com"
ORDERER_CA_PATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/${ORDERER_DOMAIN}/msp/tlscacerts/tlsca.example.com-cert.pem"
