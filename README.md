# ⌚ Luxury Watch Tokenization

> Fractional ownership of luxury watches on the blockchain — powered by **Chainlink CRE**, **ERC-1155**, and **IPFS via Pinata**.

Turn verified luxury watches into tradeable fractional tokens. Each watch is registered on-chain with full provenance data, divided into fractional shares, and backed by decentralized metadata on IPFS.

---

## ✨ Features

- **Fractional Ownership** — Divide any luxury watch into customizable fractions (e.g., 100 shares of a Rolex Daytona)
- **Chainlink CRE Integration** — Off-chain watch appraisal validation before on-chain minting via Chainlink's Runtime Environment
- **Automated IPFS Metadata** — One command generates ERC-1155 metadata from on-chain data, uploads to Pinata, and updates the contract URI
- **Primary & Secondary Market** — Buy fractions from the vault (creator) or from other holders at custom prices
- **Physical Redemption** — Collect 100% of a watch's fractions to burn them and redeem the physical timepiece
- **Batch Transfers** — Transfer multiple watch fractions in a single transaction

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      USER / TERMINAL                        │
│                                                             │
│  1. ./scripts/mint-watch.sh                                 │
│     └─ Prompts for watch details                            │
│     └─ Updates http_trigger_payload.json                    │
│     └─ Runs CRE workflow ──────────────┐                    │
│     └─ Runs Pinata upload ─────────┐   │                    │
│                                    │   │                    │
├────────────────────────────────────│───│────────────────────┤
│           OFF-CHAIN                │   │                    │
│                                    │   ▼                    │
│  ┌─────────────────────────────────┤  CRE Workflow          │
│  │  Pinata IPFS                    │  (main.ts)             │
│  │  ┌──────────┐                   │   │                    │
│  │  │ 0.json   │                   │   │ Validates watch    │
│  │  │ 1.json   │ ◄────────────────┘   │ appraisal data     │
│  │  │ ...      │                       │                    │
│  │  └──────────┘                       │ Generates DON      │
│  │   Folder CID                        │ signed report      │
│  │                                     │                    │
├──│─────────────────────────────────────│────────────────────┤
│  │        ON-CHAIN (Sepolia)           │                    │
│  │                                     ▼                    │
│  │  ┌──────────────────────┐    ┌──────────────────────┐   │
│  │  │   LuxuryWatch.sol    │◄───│ WatchMintingConsumer  │   │
│  │  │   (ERC-1155)         │    │ (CRE Report Decoder)  │   │
│  │  │                      │    └──────────────────────┘   │
│  └─►│  setBaseURI(ipfs://) │                                │
│     │  uri(id) → metadata  │                                │
│     └──────────────────────┘                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
stablecoin-ace-ccip/
├── contracts/
│   ├── LuxuryWatch.sol            # ERC-1155 — registration, minting, trading, redemption
│   ├── WatchMintingConsumer.sol    # CRE consumer — decodes DON reports → calls LuxuryWatch
│   └── IReceiverTemplate.sol      # Abstract base for CRE report receivers
├── luxury-watch-workflow/
│   ├── main.ts                    # CRE workflow — HTTP trigger → appraisal → on-chain report
│   ├── config.json                # Deployed contract addresses
│   ├── http_trigger_payload.json  # Watch data sent to the workflow
│   ├── workflow.yaml              # CRE CLI settings
│   └── package.json               # Workflow dependencies (@chainlink/cre-sdk, viem, zod)
├── scripts/
│   ├── mint-watch.sh              # Interactive — prompts for watch details, mints, uploads IPFS
│   └── pinata-upload.js           # Reads on-chain data → generates metadata → uploads to Pinata
├── metadata/                      # Auto-generated JSON metadata (local cache)
├── foundry.toml                   # Foundry config
├── project.yaml                   # CRE project settings
├── .env.example                   # Environment variables template
└── package.json                   # Root dependencies (ethers, axios, dotenv, form-data)
```

---

## 🚀 Quick Start

### Prerequisites

| Tool | Install |
|------|---------|
| **Foundry** (forge, cast) | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| **Bun** | `curl -fsSL https://bun.sh/install \| bash` |
| **CRE CLI** | [Chainlink CRE Docs](https://docs.chain.link/chainlink-functions/getting-started) |
| **Node.js** (v18+) | [nodejs.org](https://nodejs.org) |

### 1. Install Dependencies

```bash
# Solidity dependencies (OpenZeppelin)
npm install

# CRE workflow dependencies
cd luxury-watch-workflow && bun install && cd ..
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Fill in:
- `CRE_ETH_PRIVATE_KEY` — Your wallet private key (needs Sepolia ETH)
- `PINATA_JWT` — Your Pinata API JWT ([get one here](https://app.pinata.cloud/developers/api-keys))

Then load env vars:
```bash
source .env
export PRIVATE_KEY=$CRE_ETH_PRIVATE_KEY
export CRE_PROJECT_ROOT=$(pwd)
```

### 3. Compile Contracts

```bash
forge build
```

### 4. Deploy Contracts

```bash
# Deploy LuxuryWatch (ERC-1155)
forge create contracts/LuxuryWatch.sol:LuxuryWatch \
  --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast

# Copy the "Deployed to:" address, then:
export LUXURY_WATCH=<paste_address>

# Deploy WatchMintingConsumer (CRE listener)
forge create contracts/WatchMintingConsumer.sol:WatchMintingConsumer \
  --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast \
  --constructor-args $LUXURY_WATCH "0x0000000000000000000000000000000000000000" "0x64756d6d790000000000"

# Copy the "Deployed to:" address, then:
export WATCH_CONSUMER=<paste_address>
```

### 5. Update Contract Addresses

Update the deployed addresses in two places:

**`.env`:**
```env
LUXURY_WATCH_SEPOLIA=<your LUXURY_WATCH address>
WATCH_CONSUMER_SEPOLIA=<your WATCH_CONSUMER address>
```

**`luxury-watch-workflow/config.json`:**
```json
{
  "evms": [{
    "luxuryWatchAddress": "<your LUXURY_WATCH address>",
    "consumerAddress": "<your WATCH_CONSUMER address>",
    "chainSelectorName": "ethereum-testnet-sepolia",
    "gasLimit": "500000"
  }]
}
```

---

## ⌚ Usage

### Mint a Watch (One Command)

The interactive minting script handles everything:

```bash
./scripts/mint-watch.sh
```

It will prompt you for the watch brand, model, serial, fractions, and price — then automatically:
1. Updates the CRE workflow payload
2. Runs the CRE workflow to mint the watch on-chain
3. Generates ERC-1155 metadata from on-chain data
4. Uploads metadata to Pinata (IPFS)
5. Updates the contract's base URI

### Manual Step-by-Step

If you prefer running each step individually:

```bash
# 1. Edit the watch payload
nano luxury-watch-workflow/http_trigger_payload.json

# 2. Run the CRE workflow
cre workflow simulate luxury-watch-workflow \
  --target local-simulation --broadcast --trigger-index 0 \
  --non-interactive \
  --http-payload @$CRE_PROJECT_ROOT/luxury-watch-workflow/http_trigger_payload.json

# 3. Upload metadata to IPFS and update contract URI
node scripts/pinata-upload.js

# 4. (Optional) Preview without updating the contract
node scripts/pinata-upload.js --dry-run
```

### Read On-Chain Data

```bash
# Total registered watches
cast call $LUXURY_WATCH "getWatchCount()" --rpc-url $SEPOLIA_RPC

# Watch details for Token ID 0
cast call $LUXURY_WATCH "getWatchDetails(uint256)" 0 --rpc-url $SEPOLIA_RPC

# Metadata URI for Token ID 0
cast call $LUXURY_WATCH "uri(uint256)" 0 --rpc-url $SEPOLIA_RPC

# Check fraction balance
cast call $LUXURY_WATCH "balanceOf(address,uint256)" <wallet_address> 0 --rpc-url $SEPOLIA_RPC
```

---

## 📜 Smart Contract Functions

### LuxuryWatch.sol (ERC-1155)

| Function | Description |
|----------|-------------|
| `registerAndMintWatch(...)` | Register a new watch and mint fractional tokens |
| `TransferTokenWatchFromVault(...)` | Buy fractions from the original creator |
| `TransferTokenWatchfromUser(...)` | Buy fractions from another holder |
| `TransferTokenWatchBatchFromVault(...)` | Batch buy from creator |
| `TransferTokenWatchBatchFromUser(...)` | Batch buy from holder |
| `redeemForPhysical(id)` | Burn 100% of fractions to claim the physical watch |
| `UpdateChoice(id, bool)` | Toggle your fractions as "for sale" |
| `setFractionPrice(id, price)` | Set your custom resale price per fraction |
| `setBaseURI(uri)` | Update the IPFS metadata base URI (owner only) |
| `uri(id)` | Returns the IPFS metadata URL for a given token |
| `getWatchDetails(id)` | Returns brand, model, serial, total fractions |
| `getWatchCount()` | Returns total number of registered watches |

---

## 🔗 Tech Stack

| Layer | Technology |
|-------|-----------|
| Smart Contracts | Solidity ^0.8.25, OpenZeppelin ERC-1155 |
| Development | Foundry (Forge, Cast) |
| Off-Chain Orchestration | Chainlink CRE (Runtime Environment) |
| Workflow Runtime | Bun, TypeScript |
| IPFS / Metadata | Pinata, Node.js (axios, ethers) |
| Network | Ethereum Sepolia Testnet |

---

## 🧪 Sample Watch Payloads

The CRE workflow's dummy appraisal database recognizes these serials:

| Serial | Watch | Appraised Value |
|--------|-------|-----------------|
| `RLX-116500-ABC123` | Rolex Daytona | $35,000 |
| `AP-15500ST-XYZ789` | Audemars Piguet Royal Oak | $45,000 |
| `PP-5711A-DEF456` | Patek Philippe Nautilus | $120,000 |

Any other serial is auto-approved at $10,000 for demo purposes.

---

## 📄 License

MIT
