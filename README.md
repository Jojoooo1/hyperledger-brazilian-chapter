# Material created for the first-ever Hyperledger Bootcamp in Latin America

## introduction-chaincode

Folder containing:

* Material to set up a dev-mode environment in order to quickly test and prototype your chaincode.
* A chaincode example
* Scripts to start and reset the chaincode example

## introduction-network

Folder containing:

* 1 script `build.sh` to create the crypto-config material and channel-artifacts
* 2 scripts `start.sh` and `reset.sh` to start and reset the network
* 1 scripts folder:
  * Variables of `start.sh`
  * Functions used in `start.sh`
* 2 Docker compose file representing a network with 2 organizations (Orgs1 & Orgs2):
  * `docker-compose-cli.yaml` containing certificate authorities, peers, cli and the first orderer
  * `docker-compose-etcdraft2.yaml` containing the others orderers

## introduction-node-sdk

Folder containing:

* A config folder:
  * crypto-config folder corresponding of the network running
  * 1 connection profile `connection-profile-tls.json`
* `enrollAdmin.js` to enroll an admin for Orgs1
* `registerUser.js` to register a user for Orgs1
* `invoke.js` to submit a transaction to the network
* `query.js` to query the ledger
