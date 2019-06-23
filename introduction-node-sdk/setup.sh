#!/bin/bash
set -ev

# install packages
npm install
# Remove registered user
rm -rf hfc/*
# Remove crypto-config
rm -rf config/crypto-config
# Copy network crypto-config
cp -r ../introduction-network/crypto-config ./config
