#!/bin/bash

# ==============================================================================
#  AUTOMATED CHAINCODE DEPLOYMENT SCRIPT
#  Scope: Farmer, Transporter, Retailer
# ==============================================================================

# Default Variables
CC_NAME="transport"
CC_SRC_PATH="/opt/chaincode"
CHANNEL_NAME="supplychainchannel"
ORDERER_ADDRESS="orderer.supplychain.net:7050"
ORDERER_TLS_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/supplychain.net/orderers/orderer.supplychain.net/msp/tlscacerts/tlsca.supplychain.net-cert.pem"

# User Input for Versioning
CC_VERSION=${1:-"1.0"}
CC_SEQUENCE=${2:-"1"}

echo "----------------------------------------------------------------"
echo "  Deploying Chaincode: $CC_NAME"
echo "  Version: $CC_VERSION"
echo "  Sequence: $CC_SEQUENCE"
echo "----------------------------------------------------------------"

# Helper Function: Set Identity Globals
setGlobals() {
  ORG=$1
  if [ "$ORG" == "farmer" ]; then
    CORE_PEER_LOCALMSPID="FarmerMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/farmer.supplychain.net/peers/peer0.farmer.supplychain.net/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/farmer.supplychain.net/users/Admin@farmer.supplychain.net/msp
    CORE_PEER_ADDRESS=peer0.farmer.supplychain.net:7051
  elif [ "$ORG" == "transporter" ]; then
    CORE_PEER_LOCALMSPID="TransporterMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/transporter.supplychain.net/peers/peer0.transporter.supplychain.net/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/transporter.supplychain.net/users/Admin@transporter.supplychain.net/msp
    CORE_PEER_ADDRESS=peer0.transporter.supplychain.net:8051
  elif [ "$ORG" == "retailer" ]; then
    CORE_PEER_LOCALMSPID="RetailerMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/retailer.supplychain.net/peers/peer0.retailer.supplychain.net/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/retailer.supplychain.net/users/Admin@retailer.supplychain.net/msp
    CORE_PEER_ADDRESS=peer0.retailer.supplychain.net:9051
  else
    echo "Unknown Organization: $ORG"
    exit 1
  fi
}

# Wrapper for Docker Exec
exec_cli() {
  # $1 = Org, $2.. = Command
  ORG=$1
  shift
  setGlobals $ORG
  
  docker exec \
    -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
    -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
    -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
    cli "$@"
}

# 1. Package Chaincode
echo "Packaging Chaincode..."
docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
  --path ${CC_SRC_PATH} --lang node --label ${CC_NAME}_${CC_VERSION} >&log.txt
res=$?
if [ $res -ne 0 ]; then echo "Failed to package chaincode"; cat log.txt; exit 1; fi
echo "Success: Chaincode Packaged."

# 2. Install on All Peers
for org in farmer transporter retailer; do
  echo "Installing on $org..."
  exec_cli $org peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  
  if [ $res -ne 0 ]; then
    # Check if the error is just "Already installed"
    if grep -q "already successfully installed" log.txt; then
      echo "  Warning: Chaincode already installed on $org. Continuing..."
    else
      echo "Failed to install on $org"; cat log.txt; exit 1;
    fi
  else
    echo "Success: Installed on $org."
  fi
done

# 3. Query Package ID (Auto-Extraction)
echo "Querying Package ID..."
# We query the farmer to get the ID
setGlobals farmer
CC_PACKAGE_ID=$(docker exec -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS cli peer lifecycle chaincode queryinstalled | grep ${CC_NAME}_${CC_VERSION} | sed -n 's/.*Package ID: //; s/, Label:.*//p')
echo "Package ID: $CC_PACKAGE_ID"

if [ -z "$CC_PACKAGE_ID" ]; then
    echo "Error: Package ID not found."
    exit 1
fi

# 4. Approve for All Orgs
for org in farmer transporter retailer; do
  echo "Approving for $org..."
  exec_cli $org peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS \
    --ordererTLSHostnameOverride orderer.supplychain.net --tls --cafile $ORDERER_TLS_CA \
    --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION \
    --package-id $CC_PACKAGE_ID --sequence $CC_SEQUENCE >&log.txt
  res=$?
  if [ $res -ne 0 ]; then echo "Failed to approve for $org"; cat log.txt; exit 1; fi
  echo "Success: Approved for $org."
done

# 5. Commit Chaincode (Combined Command)
echo "Committing Chaincode..."
docker exec cli peer lifecycle chaincode commit -o $ORDERER_ADDRESS \
  --ordererTLSHostnameOverride orderer.supplychain.net --tls --cafile $ORDERER_TLS_CA \
  --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE \
  --peerAddresses peer0.farmer.supplychain.net:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/farmer.supplychain.net/peers/peer0.farmer.supplychain.net/tls/ca.crt \
  --peerAddresses peer0.transporter.supplychain.net:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/transporter.supplychain.net/peers/peer0.transporter.supplychain.net/tls/ca.crt \
  --peerAddresses peer0.retailer.supplychain.net:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/retailer.supplychain.net/peers/peer0.retailer.supplychain.net/tls/ca.crt >&log.txt

res=$?
if [ $res -ne 0 ]; then echo "Failed to commit chaincode"; cat log.txt; exit 1; fi
echo "----------------------------------------------------------------"
echo "  Success! Chaincode $CC_NAME version $CC_VERSION deployed."
echo "----------------------------------------------------------------"