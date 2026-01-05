#!/bin/bash
# deploy.sh
# Deploys the TypeScript Chaincode

# --- CONFIGURATION ---
CC_NAME="transport"
CC_SRC_PATH="/opt/chaincode"
CC_LANG="node"
VERSION=$1
SEQUENCE=$2

print_step "Step 1: Packaging Chaincode (TypeScript)..."
pushd $CC_SRC_PATH
npm install
npm run build
popd

peer lifecycle chaincode package ${CC_NAME}.tar.gz --path $CC_SRC_PATH --lang node --label ${CC_NAME}_${CC_VERSION}

# --- NEW: ORGANIZATION SETUP ---
# Create a dedicated directory for deployment artifacts
DEPLOY_DIR="$DIR/../deployments"
mkdir -p $DEPLOY_DIR

PACKAGE_NAME="${CC_NAME}_${VERSION}.tar.gz"
PACKAGE_PATH="${DEPLOY_DIR}/${PACKAGE_NAME}"

echo "## Starting Deployment of $CC_NAME v$VERSION (Sequence $SEQUENCE) ##"

# --- STEP 1: PACKAGE ---
echo "--- Step 1: Packaging Chaincode ---"
# We explicitly save into the deployments directory
peer lifecycle chaincode package ${PACKAGE_PATH} \
  --path ${CC_SRC_PATH} --lang ${CC_LANG} --label ${CC_NAME}_${VERSION}

if [ ! -f "$PACKAGE_PATH" ]; then
    echo "Failed to create package at $PACKAGE_PATH"
    exit 1
fi
echo "Package created at: $PACKAGE_PATH"

# --- STEP 2: INSTALL ON PEER 0 ---
echo "--- Step 2: Installing on Peer0 ---"
setGlobals 0
peer lifecycle chaincode install ${PACKAGE_PATH}

# --- STEP 3: INSTALL ON PEER 1 ---
echo "--- Step 3: Installing on Peer1 ---"
setGlobals 1
peer lifecycle chaincode install ${PACKAGE_PATH}

# --- STEP 4: GET PACKAGE ID ---
echo "--- Step 4: Querying Package ID ---"
setGlobals 0
peer lifecycle chaincode queryinstalled >&log.txt
# This sed command extracts the ID matching the CURRENT label
PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)

if [ -z "$PACKAGE_ID" ]; then
    echo "Error: Package ID not found. Installation may have failed."
    exit 1
fi
echo "Package ID is: $PACKAGE_ID"

# --- STEP 5: APPROVE ---
echo "--- Step 5: Approving for Org1 ---"
setGlobals 0
peer lifecycle chaincode approveformyorg \
  -o orderer.example.com:7050 --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME -v $VERSION \
  --package-id $PACKAGE_ID --sequence $SEQUENCE

echo "Waiting for approval..."
sleep 3

# --- STEP 6: COMMIT ---
echo "--- Step 6: Committing Chaincode ---"
peer lifecycle chaincode commit \
  -o orderer.example.com:7050 --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME -v $VERSION \
  --sequence $SEQUENCE \
  --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
  --peerAddresses peer1.org1.example.com:8051 --tlsRootCertFiles $PEER1_ORG1_CA



echo -e "${GREEN}Chaincode Deployment Complete!${NC}"