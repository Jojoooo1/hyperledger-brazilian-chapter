'use strict';
/*
 * Copyright IBM Corp All Rights Reserved
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/*
 * Chaincode Invoke
 */

const Fabric_Client = require('fabric-client');
const path = require('path');
const util = require('util');

const PROFILE_PATH = path.join(__dirname, 'config/connection-profile-tls.json');

invoke();

async function invoke() {
  console.log('\n\n --- invoke.js - start');
  try {
    console.log('Setting up client side network objects');
    // fabric client instance
    // starting point for all interactions with the fabric network
    const fabric_client = new Fabric_Client();

    // Load a network configuration object or load a JSON file and update this client with any values in the config.
    fabric_client.loadFromConfig(PROFILE_PATH);

    // Sets the state and crypto suite for use by this client. This requires that a network config has been loaded.
    // Will use the settings from the network configuration along with the system configuration to build instances
    // of the stores and assign them to this client and the crypto suites if needed.
    await fabric_client.initCredentialStores();

    // get the enrolled user from persistence and assign to the client instance
    //    this user will sign all requests for the fabric network
    const user = await fabric_client.getUserContext('user', true);
    if (user && user.isEnrolled()) {
      console.log('Successfully loaded "user" from user store');
    } else {
      throw new Error('\n\nFailed to get user.... run registerUser.js');
    }

    console.log('Successfully setup client side');
    console.log('\n\nStart query processing');

    const channel = fabric_client.getChannel('mychannel');

    const request = {
      //targets : --- letting this default to the peers assigned to the channel
      chaincodeId: 'organizacao',
      fcn: 'getDataById',
      args: ['test']
    };

    // send the query proposal to the peer
    const response = await channel.queryByChaincode(request);
    console.log(response.toString('utf-8'));
    console.log('\n\n --- invoke.js - end');
    return;
  } catch (error) {
    console.log('Unable to invoke ::' + error.toString());
  }
}
