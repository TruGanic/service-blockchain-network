#!/bin/bash

# --- CONFIGURATION ---
CHANNEL_NAME="service-channel"
DELAY=3
MAX_RETRY=5
VERBOSE="false"

# Import env.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/env.sh

echo "## STARTING NETWORK INITIALIZATION ##"

# --- STEP 1: Create Channel Block ---
echo "--- Step 1: Creating Channel Block ---"
setGlobals 0
peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME \
    -f ./channel-artifacts/${CHANNEL_NAME}.tx \
    --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls --cafile $ORDERER_CA

echo "Channel '$CHANNEL_NAME' created."

# --- STEP 2: Join Peer0 ---
echo "--- Step 2: Joining Peer0 to Channel ---"
setGlobals 0
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block
echo "Peer0 Joined."

# --- STEP 3: Join Peer1 ---
echo "--- Step 3: Joining Peer1 to Channel ---"
setGlobals 1
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block
echo "Peer1 Joined."

# --- STEP 4: Update Anchor Peers ---
echo "--- Step 4: Updating Anchor Peers for Org1 ---"
setGlobals 0
peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME \
    -f ./channel-artifacts/Org1MSPanchors.tx \
    --tls --cafile $ORDERER_CA

echo "## NETWORK INITIALIZATION COMPLETE ##"
