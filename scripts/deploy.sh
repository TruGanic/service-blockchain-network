#!/bin/bash
# deploy.sh
# Deploys the TypeScript Chaincode

# Import shared variables
source ./env.sh

print_step "Step 1: Packaging Chaincode (TypeScript)..."
pushd $CC_SRC_PATH
npm install
npm run build
popd

peer lifecycle chaincode package ${CC_NAME}.tar.gz --path $CC_SRC_PATH --lang node --label ${CC_NAME}_${CC_VERSION}

print_step "Step 2: Installing Chaincode on Peer0..."
peer lifecycle chaincode install ${CC_NAME}.tar.gz

print_step "Step 3: Querying Installed Package ID..."
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep ${CC_NAME}_${CC_VERSION} | awk -F "Package ID: " '{print $2}' | awk -F "," '{print $1}')
echo -e "${GREEN}Package ID found: ${PACKAGE_ID}${NC}"

print_step "Step 4: Approving Chaincode for Org1..."
peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION --package-id $PACKAGE_ID --sequence $CC_SEQUENCE --tls --cafile $ORDERER_CA
sleep 3

print_step "Step 5: Checking Commit Readiness..."
peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE --tls --cafile $ORDERER_CA --output json

print_step "Step 6: Committing Chaincode Definition..."
peer lifecycle chaincode commit -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE --tls --cafile $ORDERER_CA --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE

print_step "Step 7: Invoking Chaincode (InitLedger)..."
peer chaincode invoke -o $ORDERER_ADDRESS --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c '{"function":"InitLedger","Args":[]}'

echo -e "${GREEN}Chaincode Deployment Complete!${NC}"