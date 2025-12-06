#!/bin/bash

# --- BASE PATH inside the Container ---
# This matches volume mapping: ./:/opt/gopath/src/github.com/hyperledger/fabric/peer/
BASE_DIR="/opt/gopath/src/github.com/hyperledger/fabric/peer"

# 1. Common Variables
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${BASE_DIR}/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${BASE_DIR}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER1_ORG1_CA=${BASE_DIR}/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
export CHANNEL_NAME="service-channel"

# 2. Function to switch peers
setGlobals() {
  PEER=$1
  if [ $PEER -eq 0 ]; then
    echo "Using Peer0..."
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
  elif [ $PEER -eq 1 ]; then
    echo "Using Peer1..."
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=peer1.org1.example.com:8051
  else
    echo "Unknown Peer"
  fi
}