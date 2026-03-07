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
- **Hackathon Meta** — Includes a full 2-minute demo script and automated terminal workflow for the perfect submission.

---

## 📽️ Demo & Submission

For a step-by-step guide on recording your submission video, see:
👉 [**Ultimate Hackathon Walkthrough (with Scripts)**](walkthrough.md)

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
│  │        ON-CHAIN (Sepolia)           │                   │
│  │                                     ▼                   │
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
│   ├── main.ts                    # CRE workflow — appraisal logic & DON report generation
│   ├── Onboard.js                 # Internal CRE utility
│   ├── config.json                # Deployed contract addresses & Gas Settings
│   ├── http_trigger_payload.json  # Watch data sent to the workflow
│   ├── workflow.yaml              # CRE CLI settings
│   └── tsconfig.json              # TypeScript configuration
├── scripts/
│   ├── mint-watch.sh              # Interactive script — Mints & Syncs IPFS in one go
│   ├── pinata-upload.js           # Metadata generator & IPFS uploader
│   └── direct-mint.js             # Utility for direct contract interaction
├── metadata/                      # Auto-generated JSON metadata (local cache)
├── walkthrough.md                 # 🎙️ Submissions script & step-by-step demo guide
├── foundry.toml                   # Foundry config
├── project.yaml                   # CRE project settings
├── .env.example                   # Environment variables template
└── package.json                   # Root dependencies (ethers, axios, dotenv)
```

---

## 🚀 Quick Start

### Prerequisites

| Tool | Install |
|------|---------|
| **Foundry** | `curl -L https://foundry.paradigm.xyz | bash && foundryup` |
| **Bun** | `curl -fsSL https://bun.sh/install | bash` |
| **CRE CLI** | [Chainlink CRE Docs](https://docs.chain.link/chainlink-functions/getting-started) |
| **Node.js** | v18+ |

### 1. Install Dependencies

```bash
# Solidity dependencies
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
- `CRE_ETH_PRIVATE_KEY` — Admin wallet (Sepolia ETH)
- `PINATA_JWT` — Pinata API JWT

Then load:
```bash
source .env
export PRIVATE_KEY=$CRE_ETH_PRIVATE_KEY
export CRE_PROJECT_ROOT=$(pwd)
```

### 3. Deploy & Setup

Follow the detailed instructions in [**walkthrough.md**](walkthrough.md) to:
1. Deploy `LuxuryWatch` and `WatchMintingConsumer`.
2. Update `luxury-watch-workflow/config.json` with the new addresses and a `gasLimit` of `"1000000"`.
3. Build the workflow: `cre workflow build luxury-watch-workflow`.

---

## ⌚ Usage

### The "All-in-One" Minting Command

Run the interactive script to tokenize a watch and sync it to IPFS:

```bash
./scripts/mint-watch.sh
```

**What it does:**
1. Triggers the Chainlink CRE workflow.
2. Mints the watch on-chain (verified appraisal).
3. Generates metadata and uploads it to IPFS via Pinata.
4. Auto-updates the smart contract's `baseURI`.

### Secondary Trading

Simulate trading via terminal:

```bash
# Set price for your fractions (e.g., 0.5 ETH)
cast send $LUXURY_WATCH "setFractionPrice(uint256,uint256)" 0 500000000000000000 --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC

# List them for sale
cast send $LUXURY_WATCH "UpdateChoice(uint256,bool)" 0 true --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC
```

---

## 📜 Smart Contract Functions

| Function | Description |
|----------|-------------|
| `registerAndMintWatch(...)` | Register watch & mint fractions via CRE |
| `TransferTokenWatchFromVault(...)` | Buy fractions from the creator (vault) |
| `TransferTokenWatchfromUser(...)` | Peer-to-peer fractional purchase |
| `redeemForPhysical(id)` | Burn 100% fractions to redeem physical asset |
| `UpdateChoice(id, bool)` | Toggle fractions for sale |
| `setFractionPrice(id, price)` | Set custom resale price |
| `uri(id)` | Returns immutable IPFS metadata link |

---

## 🧪 Demo Data

The CRE workflow recognizes these test serials for specific valuations:
- `RLX-116500-ABC123` (Rolex Daytona): $35,000
- `AP-15500ST-XYZ789` (AP Royal Oak): $45,000
- `PP-5711A-DEF456` (Patek Philippe): $120,000

---

## 📄 License
MIT
