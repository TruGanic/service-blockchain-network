#!/bin/bash

# Function to set globals for Farmer
setFarmer() {
  echo "Switching Identity to: FARMER"
  export CORE_PEER_LOCALMSPID="FarmerMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/farmer.supplychain.net/peers/peer0.farmer.supplychain.net/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/farmer.supplychain.net/users/Admin@farmer.supplychain.net/msp
  export CORE_PEER_ADDRESS=peer0.farmer.supplychain.net:7051
}

# Function to set globals for Transporter
setTransporter() {
  echo "Switching Identity to: TRANSPORTER"
  export CORE_PEER_LOCALMSPID="TransporterMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/transporter.supplychain.net/peers/peer0.transporter.supplychain.net/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/transporter.supplychain.net/users/Admin@transporter.supplychain.net/msp
  export CORE_PEER_ADDRESS=peer0.transporter.supplychain.net:8051
}

# Function to set globals for Retailer
setRetailer() {
  echo "Switching Identity to: RETAILER"
  export CORE_PEER_LOCALMSPID="RetailerMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/retailer.supplychain.net/peers/peer0.retailer.supplychain.net/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/retailer.supplychain.net/users/Admin@retailer.supplychain.net/msp
  export CORE_PEER_ADDRESS=peer0.retailer.supplychain.net:9051
}

echo "Environment variables loaded!"
echo "Use commands: setFarmer, setTransporter, or setRetailer"