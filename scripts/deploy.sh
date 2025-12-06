#!/bin/bash

# --- CONFIGURATION ---
CC_NAME="basic"
CC_SRC_PATH="/opt/chaincode"
CC_LANG="node"
VERSION=$1
SEQUENCE=$2

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ./deploy.sh <version> <sequence>"
  echo "Example: ./deploy.sh 1.0 1"
  exit 1
fi

# Import env.sh (Looking in the current directory)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/env.sh

echo "## Starting Deployment of $CC_NAME v$VERSION (Sequence $SEQUENCE) ##"

# --- STEP 1: PACKAGE ---
echo "--- Step 1: Packaging Chaincode ---"
rm -f ${CC_NAME}_${VERSION}.tar.gz
peer lifecycle chaincode package ${CC_NAME}_${VERSION}.tar.gz \
  --path ${CC_SRC_PATH} --lang ${CC_LANG} --label ${CC_NAME}_${VERSION}

# --- STEP 2: INSTALL ON PEER 0 ---
echo "--- Step 2: Installing on Peer0 ---"
setGlobals 0
peer lifecycle chaincode install ${CC_NAME}_${VERSION}.tar.gz

# --- STEP 3: INSTALL ON PEER 1 ---
echo "--- Step 3: Installing on Peer1 ---"
setGlobals 1
peer lifecycle chaincode install ${CC_NAME}_${VERSION}.tar.gz

# --- STEP 4: GET PACKAGE ID ---
echo "--- Step 4: Querying Package ID ---"
setGlobals 0
peer lifecycle chaincode queryinstalled >&log.txt
PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
echo "Package ID is: $PACKAGE_ID"

# --- STEP 5: APPROVE ---
echo "--- Step 5: Approving for Org1 ---"
setGlobals 0
peer lifecycle chaincode approveformyorg \
  -o orderer.example.com:7050 --tls --cafile $ORDERER_CA \
  --channelID $CHANNEL_NAME --name $CC_NAME --version $VERSION \
  --package-id $PACKAGE_ID --sequence $SEQUENCE

echo "Waiting for approval..."
sleep 3

# --- STEP 6: COMMIT ---
echo "--- Step 6: Committing Chaincode ---"
peer lifecycle chaincode commit \
  -o orderer.example.com:7050 --tls --cafile $ORDERER_CA \
  --channelID $CHANNEL_NAME --name $CC_NAME --version $VERSION \
  --sequence $SEQUENCE \
  --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
  --peerAddresses peer1.org1.example.com:8051 --tlsRootCertFiles $PEER1_ORG1_CA

# --- STEP 7: INVOKE INIT ---
echo "--- Step 7: Initializing Ledger ---"
sleep 3
peer chaincode invoke \
  -o orderer.example.com:7050 --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME \
  --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
  --peerAddresses peer1.org1.example.com:8051 --tlsRootCertFiles $PEER1_ORG1_CA \
  -c '{"function":"InitLedger","Args":[]}'

echo "## DEPLOYMENT COMPLETE ##"