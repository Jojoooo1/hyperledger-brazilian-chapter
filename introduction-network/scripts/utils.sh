# $1 organization index | $2 peer number
setVariables() {
  # set -x

  ORGANIZATION_INDEX=$1
  PEER_NUMBER=$2
  # PEER_NUMBER ($2) start at 1 (because of loop value) but PEER_NAME at 0 => do a subtraction
  if [ -z "$PEER_NUMBER" ]; then PEER_NUMBER=0; fi

  PEER_PORT_INDEX=${ORGANIZATION_PEER_STARTING_PORT[$ORGANIZATION_INDEX]} # Gets starting port
  PEER_PORT=$(($PEER_PORT_INDEX + $PEER_NUMBER * 1000))                   # Calc starting port + peer number

  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/users/Admin@${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/msp
  CORE_PEER_ADDRESS=peer${PEER_NUMBER}.${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}:$PEER_PORT
  CORE_PEER_LOCALMSPID=${ORGANIZATION_MSPID[ORGANIZATION_INDEX]}
  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/peers/peer${PEER_NUMBER}.${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/tls/ca.crt

  # set +x
}

replaceCAPrivateKey() {
  SET=$1
  # Set PrivateKey
  if [ $SET -eq 1 ]; then
    for i in ${!ORGANIZATION_DOMAIN[@]}; do # @ get all value of the array ${} exec the value ! represent the index
      PRIV_KEY=$(ls crypto-config/peerOrganizations/${ORGANIZATION_DOMAIN[$i]}/ca/*_sk | xargs -n1 basename)
      sed -i "s/CA${i}_PRIVATE_KEY/${PRIV_KEY}/g" $COMPOSE_FILE
    done
  # Set default variable
  else
    for i in ${!ORGANIZATION_DOMAIN[@]}; do
      PRIV_KEY=$(ls crypto-config/peerOrganizations/${ORGANIZATION_DOMAIN[$i]}/ca/*_sk | xargs -n1 basename)
      sed -i "s/${PRIV_KEY}/CA${i}_PRIVATE_KEY/g" $COMPOSE_FILE
    done
  fi
}

loadCAPrivateKey() {
  for i in ${!ORGANIZATION_DOMAIN[@]}; do # @ get all value of the array ${} exec the value ! represent the index
    export CA${i}_PRIVATE_KEY=$(ls crypto-config/peerOrganizations/${ORGANIZATION_DOMAIN[$i]}/ca/*_sk | xargs -n1 basename)
  done
}

createChannel() {
  if [ $CORE_PEER_TLS_ENABLED = true ]; then
    docker exec -it cli sh -c "\
    peer channel create -o ${ORDERER_DOMAIN}:7050 --tls --cafile $ORDERER_CA_PATH -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx  \
    "
  else
    docker exec -it cli sh -c "\
    peer channel create -o ${ORDERER_DOMAIN}:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx  \
    "
  fi
}

joinPeersTochannel() {
  for i in ${!ORGANIZATION_DOMAIN[@]}; do # Loop every organization
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
      setVariables $i $j
      docker exec -it \
        -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
        -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
        -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
        cli sh -c "peer channel join -b ${CHANNEL_NAME}.block"
    done

  done
}

setAnchorPeers() {
  for i in ${!ORGANIZATION_DOMAIN[@]}; do # Loop every organization

    if [ $CORE_PEER_TLS_ENABLED = true ]; then
      ANCHOR_COMMAND="peer channel update -o ${ORDERER_DOMAIN}:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA_PATH -f ./channel-artifacts/${ORGANIZATION_NAME[$i]}-anchors.tx "
    else
      ANCHOR_COMMAND="peer channel update -o ${ORDERER_DOMAIN}:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${ORGANIZATION_NAME[$i]}-anchors.tx"
    fi

    # Update channel with anchor peer0
    setVariables $i 0
    docker exec -it \
      -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
      -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
      -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
      -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
      cli sh -c "$ANCHOR_COMMAND"

  done
}

# Install multiple chaincodes
installChaincodeToPeers() {
  for k in ${!CHAINCODE_NAME[@]}; do # Loop every chaincode
    for i in ${!ORGANIZATION_DOMAIN[@]}; do # Loop every organization

      for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
        setVariables $i $j
        docker exec -it \
          -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
          -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
          -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
          -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
          cli sh -c "peer chaincode install -n ${CHAINCODE_NAME[$k]} -v 1.0 -p ${CHAINECODE_PATH}${CHAINCODE_NAME[$k]} -l $LANGUAGE"
      done

    done
  done
}

initializeChaincodeContainer() {
  for i in ${!CHAINCODE_NAME[@]}; do # Loop every chaincode

    # Instantiate chaincode in orgs sets in CLI environment
    if [ $CORE_PEER_TLS_ENABLED = true ]; then
      docker exec -it cli sh -c "peer chaincode instantiate \
      -o ${ORDERER_DOMAIN}:7050 --tls --cafile $ORDERER_CA_PATH \
      -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$i]} -l $LANGUAGE -v 1.0 \
      -c '{\"Args\":[\"\"]}' \
      -P $CHAINCODE_POLICY \
      "
    else
      docker exec -it cli sh -c "peer chaincode instantiate \
      -o ${ORDERER_DOMAIN}:7050 \
      -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$i]} -l $LANGUAGE -v 1.0 \
      -c '{\"Args\":[\"\"]}' \
      -P $CHAINCODE_POLICY \
      "
    fi

    sleep 4

    # Query other peer in orgs sets in CLI environment to start containter
    if [ ${ORGANIZATION_PEER_NUMBER[0]} -gt 1 ]; then # if peer > 1
      for j in 1 ${ORGANIZATION_PEER_NUMBER[0]}; do # Loop every peer
        if [ $j -gt 1 ]; then # escape first value cause already started in instantiate command

          PEER_NUMBER=$(($j - 1))
          PEER_PORT=$((7051 + 1000 * $PEER_NUMBER)) # instantiating peer port start at 7051

          docker exec -it cli sh -c "\
          CORE_PEER_ADDRESS=peer$PEER_NUMBER.${ORGANIZATION_DOMAIN[0]}:$PEER_PORT \
          CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATION_DOMAIN[0]}/peers/peer$(($j - 1)).${ORGANIZATION_DOMAIN[0]}/tls/ca.crt \
          peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$i]} -c '{\"Args\":[\"getDataById\", \"instantiate\"]}' \
          "
        fi
      done
    fi

  done
}

# TODO
# initializeChaincodeContainerWithPrivateCollection() {}

startChaincodeContainer() {

  ORGANIZATIONS=("${ORGANIZATION_DOMAIN[@]:1}")        # Remove 1st value because already instantiated in initializeChaincodeContainer()
  PEER_NUMBER_SET=("${ORGANIZATION_PEER_NUMBER[@]:1}") # Remove 1st value because already instantiated in initializeChaincodeContainer()

  for k in ${!CHAINCODE_NAME[@]}; do # Loop every chaincode
    for i in ${!ORGANIZATIONS[@]}; do #  Loop every organization

      ORGANIZATION_START_INDEX=$(($i + 1)) # Loop will start at 1 because already instantiated in initializeChaincodeContainer()

      for ((j = 0; j < ${PEER_NUMBER_SET[$i]}; j++)); do # loop every peer
        setVariables $ORGANIZATION_START_INDEX $j
        docker exec -it \
          -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
          -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
          -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
          -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
          cli sh -c "peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$k]} -c '{\"Args\":[\"getDataById\", \"instantiate\"]}' && sleep 2"
      done

    done
  done
}
