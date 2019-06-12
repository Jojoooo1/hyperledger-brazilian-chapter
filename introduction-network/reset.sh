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


# look for Hyperledger and dev-peers related containers
dockers=$(docker ps -a |grep "hyperledger\|dev-peer" | awk '{print $1}')
if [[ $dockers ]]; then
	docker rm -f $dockers
fi

# Remove Hyperledger chaincode images
images=$(docker images dev* -q)
if [[ $images ]]; then
	docker rmi $images
fi

# Remove all volumes
docker volume prune

sudo rm -rf fabric-ca-server
sudo rm -rf ../hfc/*
