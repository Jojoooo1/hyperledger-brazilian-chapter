# $1 organization index | $2 peer number
setVariables() {
  ORGANIZATION_INDEX=$1
  if [ $2 -eq 0 ]; then # True if the lengh of STRING is zero
    PEER_NUMBER=0
  else
    PEER_NUMBER=$(($2 - 1)) # PEER_NUMBER start at 1 but PEER_NAME at 0
  fi
  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/users/Admin@${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/msp
  CORE_PEER_ADDRESS=peer${PEER_NUMBER}.${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}:7051
  CORE_PEER_LOCALMSPID=${ORGANIZATION_MSPID[ORGANIZATION_INDEX]}
  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/peers/peer${PEER_NUMBER}.${ORGANIZATION_DOMAIN[ORGANIZATION_INDEX]}/tls/ca.crt
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
  for i in ${!ORGANIZATION_DOMAIN[@]}; do
    if [ ${ORGANIZATION_PEER_NUMBER[$i]} -gt 1 ]; then

      # All peers join the channel
      for j in 1 ${ORGANIZATION_PEER_NUMBER[$i]}; do
        setVariables $i $j
        docker exec -it \
          -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
          -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
          -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
          -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
          cli sh -c "peer channel join -b ${CHANNEL_NAME}.block"
      done

    else

      # Unique peer join the channel
      setVariables $i 0
      docker exec -it \
        -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
        -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
        -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
        cli sh -c "peer channel join -b ${CHANNEL_NAME}.block"

    fi
  done
}

setAnchorPeers() {
  for i in ${!ORGANIZATION_NAME[@]}; do

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
  for k in ${!CHAINCODE_NAME[@]}; do
    for i in ${!ORGANIZATION_DOMAIN[@]}; do

      if [ ${ORGANIZATION_PEER_NUMBER[$i]} -gt 1 ]; then

        for j in 1 ${ORGANIZATION_PEER_NUMBER[$i]}; do
          setVariables $i $j
          docker exec -it \
            -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
            -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
            -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
            -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
            cli sh -c "peer chaincode install -n ${CHAINCODE_NAME[$k]} -v 1.0 -p ${CHAINECODE_PATH}${CHAINCODE_NAME[$k]} -l $LANGUAGE"
        done

      else
        setVariables $i 0
        docker exec -it \
          -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
          -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
          -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
          -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
          cli sh -c "peer chaincode install -n ${CHAINCODE_NAME[$k]} -v 1.0 -p ${CHAINECODE_PATH}${CHAINCODE_NAME[$k]} -l $LANGUAGE"
      fi

    done
  done
}

initializeChaincodeContainer() {
  for i in ${!CHAINCODE_NAME[@]}; do

    # instantiate chaincode on first Org (registered in CLI container)
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

    # Query other peer in first Org to instantiate chaincode if peer gt than 1
    if [ ${ORGANIZATION_PEER_NUMBER[0]} -gt 1 ]; then
      for j in 1 ${ORGANIZATION_PEER_NUMBER[0]}; do
        if [ $j -gt 1 ]; then
          # escape first value
          docker exec -it cli sh -c "\
          CORE_PEER_ADDRESS=peer$(($j - 1)).${ORGANIZATION_DOMAIN[0]}:7051 \
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
  # if INSTANTIATING_HOST remove 1st value in array because already been initialized in initializeChaincodeContainer
  if [ $INSTANTIATING_HOST = true ]; then
    ORGANIZATIONS=("${ORGANIZATION_DOMAIN[@]:1}")
    PEER_NUMBER=("${ORGANIZATION_PEER_NUMBER[@]:1}")
    MSP_ID=("${ORGANIZATION_MSPID[@]:1}")
  else
    ORGANIZATIONS=${ORGANIZATION_DOMAIN[@]} # doesnt remove if other host
    PEER_NUMBER=${ORGANIZATION_PEER_NUMBER[@]}
    MSP_ID=${ORGANIZATION_MSPID[@]}
  fi

  for k in ${!CHAINCODE_NAME[@]}; do
    for i in ${!ORGANIZATIONS[@]}; do

      if [ ${PEER_NUMBER[$i]} -gt 1 ]; then # if peers number > 1
        for j in 1 ${PEER_NUMBER[$i]}; do
          docker exec -it cli sh -c "\
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATIONS[$i]}/users/Admin@${ORGANIZATIONS[$i]}/msp \
        CORE_PEER_ADDRESS=peer$(($j - 1)).${ORGANIZATIONS[$i]}:7051 \
        CORE_PEER_LOCALMSPID=${MSP_ID[$i]} \
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATIONS[$i]}/peers/peer$(($j - 1)).${ORGANIZATIONS[$i]}/tls/ca.crt \
        peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$k]} -c '{\"Args\":[\"getDataById\", \"instantiate\"]}' && sleep 2 \
        "
        done
      else
        docker exec -it cli sh -c "\
      CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATIONS[$i]}/users/Admin@${ORGANIZATIONS[$i]}/msp \
      CORE_PEER_ADDRESS=peer0.${ORGANIZATIONS[$i]}:7051 \
      CORE_PEER_LOCALMSPID=${MSP_ID[$i]} \
      CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORGANIZATIONS[$i]}/peers/peer0.${ORGANIZATIONS[$i]}/tls/ca.crt \
      peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$k]} -c '{\"Args\":[\"getDataById\", \"instantiate\"]}' && sleep 2 \
      "
      fi

    done
  done
}
