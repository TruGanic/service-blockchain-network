# 🛡️ Service Blockchain Network

A production-ready Hyperledger Fabric network designed for secure, permissioned asset management. This project demonstrates a complete blockchain infrastructure featuring custom channel creation, TypeScript chaincode (Smart Contracts), and automated deployment scripts using Docker containers.

---

## 📖 Table of Contents
- [Architecture](#-architecture)
- [Technologies](#-technologies)
- [Folder Structure](#-folder-structure)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)

---

## 🏛 Architecture

The network consists of a single organization (`Org1`) operating under a permissioned consortium.

* **Orderer Node:** `orderer.example.com` (Raft Consensus) - Sequences transactions into blocks.
* **Peer Nodes:**
    * `peer0.org1.example.com` (Endorser/Committer)
    * `peer1.org1.example.com` (High Availability Redundancy)
* **Database:** CouchDB (World State) - Enables rich queries on asset data.
* **Smart Contract:** Written in TypeScript, running in dedicated external Docker containers (`dev-peer...`).
* **Channel:** `service-channel` - Private ledger for transaction isolation.

---

## 🛠 Technologies

* **Hyperledger Fabric v2.5+** - Enterprise Blockchain Framework.
* **Docker & Docker Compose** - Container orchestration.
* **Node.js & TypeScript** - Smart Contract (Chaincode) development.
* **Bash Scripts** - Automated network initialization and lifecycle management.
* **Linux (Debian/WSL2)** - Host Operating System.

---

## 📂 Folder Structure

```text
service-blockchain-network/
├── bin/                    # Hyperledger Fabric Binaries (cryptogen, peer, etc.)
├── config/                 # Core configuration files (core.yaml, orderer.yaml)
├── channel-artifacts/      # Generated genesis blocks and channel transactions
├── crypto-config/          # Cryptographic MSPs (Certificates & Keys)
├── chaincode-typescript/   # Smart Contract Source Code
│   ├── src/                # Asset logic
│   ├── package.json        # Dependencies
│   └── dist/               # Compiled JavaScript (after build)
├── network-config/         # Network Configuration
│   ├── docker-compose-test-net.yaml  # Container definitions
│   ├── configtx.yaml       # Channel & Profile configurations
│   ├── crypto-config.yaml  # Crypto material definitions
│   └── scripts/            # Automation Scripts
│       ├── env.sh          # Environment Variable Helper
│       ├── init_network.sh # Channel Creation & Joining
│       └── deploy.sh       # Chaincode Lifecycle (Install/Approve/Commit)
