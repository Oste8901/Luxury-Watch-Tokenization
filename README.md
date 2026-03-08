# ⌚ Luxury Watch Tokenization

> **"Turning Timeless Assets into Liquid Capital."** 🚀
> Fractional ownership of luxury watches on the blockchain — powered by **Chainlink CRE**, **ERC-1155**, and **IPFS via Pinata**.

---

## 🏆 Project Success: A Truly Decentralized Marketplace
We have successfully implemented a **P2P Luxury Watch Ecosystem** that bridges high-value physical assets with decentralized finance. Unlike traditional models where a single admin controls the "vault," our platform empowers **any user** to become a creator.

### **How We Achieved This:**
- **Decentralized Creator Economy**: Any account can register and tokenize a watch. The registry assigns ownership directly to the creator, enabling instant, direct payouts from buyers.
- **Chainlink CRE Trust Layer**: We use Chainlink's Runtime Environment to validate off-chain physical appraisal data before a single token is minted on-chain. This ensures every digital fraction is backed by an authenticated physical asset.
- **Automated Metadata Pipeline**: A seamless workflow that links on-chain registration with decentralized storage on IPFS, providing transparent provenance for every watch.

---

## ✨ Key Features

- **💎 Fractional Ownership** — Divide luxury timepieces into customizable fractions (ERC-1155).
- **🛡️ Chainlink CRE Integration** — Secure, DON-signed reports for on-chain watch registration.
- **☁️ Automated IPFS Metadata** — Syncs watch images and specs to Pinata with a single command.
- **💳 Instant Creator Payouts** — Primary sale revenue flows directly to the watch creator's wallet.
- **📈 P2P Secondary Market** — A fully decentralized marketplace where holders set their own prices and trade peer-to-peer.
- **🔥 Physical Redemption** — Burn 100% of fractions to unlock the physical redemption event.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      USER / TERMINAL                        │
│                                                             │
│  1. ./scripts/mint-watch.sh                                 │
│     └─ Resolves User Identity (Admin or Buyer)              │
│     └─ Validates off-chain appraisal data via CRE           │
│     └─ Orchestrates IPFS Upload and On-Chain Registration   │
│                                                             │
├────────────────────────────────────┬────────────────────────┤
│           OFF-CHAIN                │       CHAINLINK CRE    │
│                                    │                        │
│  ┌─────────────────────────────┐   │  ┌──────────────────┐  │
│  │  Pinata IPFS (Metadata Storage)│   │  CRE Workflow     │  │
│  │  Folder CID (e.g. 0.json)   ◄───┼──┤ (consensus report)│  │
│  └─────────────────────────────┘   │  └────────┬─────────┘  │
│                                    │           │            │
├────────────────────────────────────┼───────────▼────────────┤
│        ON-CHAIN (Sepolia)          │   REGISTRATION FLOW    │
│                                    │                        │
│  ┌──────────────────────┐          │  ┌──────────────────┐  │
│  │   LuxuryWatch.sol    │◄─────────┼──┤ WatchConsumer.sol│  │
│  │   (ERC-1155 Registry)│          │  │ (Report Decoder) │  │
│  └──────────┬───────────┘          │  └──────────────────┘  │
│             │                      │                        │
│             ▼                      │                        │
│  [INSTANT OWNER PAYOUTS]           │                        │
└────────────────────────────────────┴────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Install & Configure
```bash
# Install root & workflow dependencies
npm install && (cd luxury-watch-workflow && bun install)

# Setup Environment
cp .env.example .env && source .env
```

### 2. The "Ultimate" Minting Workflow
Use our interactive script to tokenize a watch from any account (Admin or Buyer):
```bash
chmod +x ./scripts/mint-watch.sh
./scripts/mint-watch.sh
```

### 3. Demo the Marketplace
Follow our [**Step-by-Step Walkthrough**](walkthrough.md) to showcase:
- Admin-to-Buyer primary sales.
- **NEW**: Buyer-to-Admin decentralized creator sales.
- Peer-to-Peer secondary market trading.

---

## 📜 Smart Contract Core

| Function | Role in the Ecosystem |
|----------|----------------------|
| `registerAndMintWatch` | The CRE-powered entry point for new assets. |
| `TransferTokenWatchFromVault` | Buying "New" fractions directly from the creator. |
| `TransferTokenWatchfromUser` | Secondary market trading between any two wallets. |
| `redeemForPhysical` | The ultimate lifecycle end-point: reclaiming the physical asset. |

---

## 📄 License
MIT — *Built with passion for the Chainlink CRE Hackathon.*
