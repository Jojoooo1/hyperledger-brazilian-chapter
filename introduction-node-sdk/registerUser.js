'use strict';
/*
 * Copyright IBM Corp All Rights Reserved
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/*
 * Register and Enroll a user
 */

var Fabric_Client = require('fabric-client');
var path = require('path');

const PROFILE_PATH = path.join(__dirname, 'config/connection-profile-tls.json');

async function registerUser() {
  try {
    // Creates Fabric client instance
    var fabric_client = new Fabric_Client();

    // Load a network configuration object or load a JSON file and update this client with any values in the config.
    fabric_client.loadFromConfig(PROFILE_PATH);

    // Sets the state and crypto suite for use by this client. This requires that a network config has been loaded.
    // Will use the settings from the network configuration along with the system configuration to build instances
    // of the stores and assign them to this client and the crypto suites if needed.
    await fabric_client.initCredentialStores();

    // This function attempts to load the user by name from the local storage (via the KeyValueStore interface).
    const admin = await fabric_client.getUserContext('admin', true);
    if (!admin) throw new Error('Failed to get admin.... run enrollAdmin.js');

    // Returns a CertificateAuthority implementation as defined by the settings in the currently loaded
    // network configuration and the client configuration. A network configuration must be loaded for
    // this get method to return a Certificate Authority. A crypto suite must be assigned to this client
    // instance. Running the 'initCredentialStores' method will build the stores and create a crypto suite
    // as defined in the network configuration.
    const fabric_ca_client = fabric_client.getCertificateAuthority('ca.org1.example.com');

    // Register a new user and return the enrollment secret
    const secret = await fabric_ca_client.register(
      { enrollmentID: 'user', affiliation: 'org1.department1', role: 'client' },
      admin
    );
    // Enroll a registered user in order to receive a signed X509 certificate
    let enrollment = await fabric_ca_client.enroll({ enrollmentID: 'user', enrollmentSecret: secret });

    // Returns a User object with signing identities based on the private key and the corresponding x509 certificate.
    // This allows applications to use pre-existing crypto materials (private keys and certificates) to construct user
    // objects with signing capabilities, as an alternative to dynamically enrolling users with fabric-ca
    const user = await fabric_client.createUser({
      username: 'user',
      mspid: 'Org1MSP',
      cryptoContent: { privateKeyPEM: enrollment.key.toBytes(), signedCertPEM: enrollment.certificate }
    });

    return user.toString();
  } catch (error) {
    return error;
  }
}

void (async function() {
  const result = await registerUser();
  console.log(result);
})();
