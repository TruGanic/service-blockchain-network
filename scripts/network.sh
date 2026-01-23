#!/bin/bash
# network.sh
# Reset, Generate, and Start the Network

# Import shared variables
source ./env.sh

# ---------------------------------------------------------------------------
# 1. CLEANUP
# ---------------------------------------------------------------------------
print_step "Step 1: Cleaning up old network artifacts and containers..."

if [ -f "$COMPOSE_FILE" ]; then
  docker compose -f $COMPOSE_FILE down --volumes --remove-orphans
else
  print_error "Docker compose file $COMPOSE_FILE not found."
  exit 1
fi

rm -rf channel-artifacts
rm -rf crypto-config
mkdir channel-artifacts

# ---------------------------------------------------------------------------
# 2. GENERATE CRYPTO MATERIAL
# ---------------------------------------------------------------------------
print_step "Step 2: Generating Crypto Material..."

if [ -f "crypto-config.yaml" ]; then
  cryptogen generate --config=./crypto-config.yaml --output="crypto-config"
  if [ $? -ne 0 ]; then
    print_error "Failed to generate crypto material..."
    exit 1
  fi
else
  print_error "crypto-config.yaml not found!"
  exit 1
fi

# ---------------------------------------------------------------------------
# 3. GENERATE GENESIS BLOCK
# ---------------------------------------------------------------------------
print_step "Step 3: Generating Genesis Block ($SYS_CHANNEL)..."

configtxgen -profile $GENESIS_PROFILE -outputBlock ./channel-artifacts/genesis.block -channelID $SYS_CHANNEL
if [ $? -ne 0 ]; then
  print_error "Failed to generate genesis block..."
  exit 1
fi

# ---------------------------------------------------------------------------
# 4. GENERATE CHANNEL TRANSACTION
# ---------------------------------------------------------------------------
print_step "Step 4: Generating Application Channel Tx ($CHANNEL_NAME)..."

configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
if [ $? -ne 0 ]; then
  print_error "Failed to generate channel transaction..."
  exit 1
fi

# ---------------------------------------------------------------------------
# 5. GENERATE ANCHOR PEER TRANSACTIONS
# ---------------------------------------------------------------------------
print_step "Step 5: Generating Anchor Peer Update for Org1MSP..."

configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
if [ $? -ne 0 ]; then
  print_error "Failed to generate anchor peer update..."
  exit 1
fi

# ---------------------------------------------------------------------------
# 6. START THE NETWORK
# ---------------------------------------------------------------------------
print_step "Step 6: Starting the Docker Network..."

docker compose -f $COMPOSE_FILE up -d
if [ $? -ne 0 ]; then
  print_error "Failed to start docker containers..."
  exit 1
fi

echo -e "${GREEN}SUCCESS! Network is up.${NC}"