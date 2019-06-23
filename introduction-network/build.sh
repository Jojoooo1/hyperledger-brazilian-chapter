#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Exit on first error, print all commands.
set -e

# FABRIC_CFG_PATH="configtx.yaml" # Config used by configtxgen
CRYPTO_CONFIG="crypto-config.yaml"

CHANNEL_NAME=mychannel
ORGANIZATION_NAME=(Org1MSP Org2MSP)

# 1. Generate crypto-config Folder containing all CA, PEER, TLS, NETWORK ADMIN, certificate etc.
function generateCert() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi

  rm -Rf crypto-config
  mkdir crypto-config

  set -x
  cryptogen generate --config=./$CRYPTO_CONFIG
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
}

# 2. Create Genesis block with initial consortium definition and anchorPeers
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  rm -Rf ./channel-artifacts/*

  # Create Genesis block defined by profile OrgsOrdererGenesis in configtx.yaml
  set -x
  configtxgen -profile SampleMultiNodeEtcdRaft -outputBlock ./channel-artifacts/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

  # Create initial channel configuration defined by profile OrgsChannel in configtx.yaml
  set -x
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  # Create anchorPeer configuration defined in profile OneOrgChannel in configtx.yaml
  for i in ${!ORGANIZATION_NAME[@]}; do
    set -x
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/${ORGANIZATION_NAME[$i]}-anchors.tx -channelID $CHANNEL_NAME -asOrg ${ORGANIZATION_NAME[$i]}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate ${ORGANIZATION_NAME[$i]} Anchor peer configuration transaction..."
      exit 1
    fi
  done

}

generateCert
generateChannelArtifacts
