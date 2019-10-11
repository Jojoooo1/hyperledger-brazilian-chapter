#!/bin/bash
set -ev

# import var & utils lib
. ./scripts/env_var.sh
. ./scripts/utils.sh

DIR=$PWD

# Loads CA private key
loadCAPrivateKey

# mount docker containers

docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_RAFT down
docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_RAFT up -d

# wait for Hyperledger Fabric to start
sleep 4

# 1. Create the channel
createChannel
sleep 8

# 2.1 Join all peer to the channel
joinPeersTochannel
sleep 2

# 2.2 Set anchor peers
setAnchorPeers
sleep 2

# 3. Install chaincode to every peers
installChaincodeToPeers
sleep 3

# 4.1 Instantiate chaincode container on 1stOrg
initializeChaincodeContainer
sleep 3

# 4.3 Start chaincode container to all others peers
startChaincodeContainer
