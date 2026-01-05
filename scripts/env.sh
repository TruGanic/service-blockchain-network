#!/bin/bash
# env.sh
# Shared Environment Variables & Functions

# --- Paths & Network Config ---
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}
export COMPOSE_FILE="docker-compose-test-net.yaml"
export GENESIS_PROFILE="OrdererGenesis"
export CHANNEL_PROFILE="ServiceChannel"
export SYS_CHANNEL="system-channel"
export CHANNEL_NAME="service-channel" 

# --- Orderer Config ---
export ORDERER_ADDRESS="localhost:7050"
export ORDERER_CA=${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# --- Org1 Peer Config ---
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# --- Chaincode Config ---
export CC_NAME="basic"
export CC_SRC_PATH="../chaincode-typescript"
export CC_VERSION="1.0"
export CC_SEQUENCE="1"

# --- Helper Functions & Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}====== $1 ======${NC}"; }
print_error() { echo -e "${RED}ERROR: $1${NC}"; }