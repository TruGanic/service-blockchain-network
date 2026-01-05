# Delete old channel blocks
rm -rf channel-artifacts
mkdir channel-artifacts

# Regenerate Genesis Block (System Channel)
export FABRIC_CFG_PATH=$PWD
configtxgen -profile OrdererGenesis -outputBlock ./channel-artifacts/genesis.block -channelID system-channel

# Regenerate Channel Transaction
configtxgen -profile ServiceChannel -outputCreateChannelTx ./channel-artifacts/service-channel.tx -channelID service-channel

# Regenerate Anchor Peer Update
configtxgen -profile ServiceChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID service-channel -asOrg Org1MSP


# The "Clean" Launch
export COMPOSE_PROJECT_NAME=service-blockchain
export FABRIC_VERSION=2.5.4
export CA_VERSION=1.5.7

docker compose -f docker-compose-test-net.yaml up -d