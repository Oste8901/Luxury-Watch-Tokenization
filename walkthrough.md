# Luxury Watch Tokenization — Ultimate Hackathon Walkthrough 🎙️

This guide covers everything you need to confidently run your luxury watch tokenization demo and record your **2-minute submission video**. 

> [!TIP]
> **Video Timing Goal:** 2 Minutes Total.
> - **Intro:** 20s
> - **Setup/Deploy:** 30s
> - **Auto-Mint/IPFS:** 40s
> - **Trading Demo:** 20s
> - **Validation:** 10s

> [!IMPORTANT]
> **🎙️ Intro Script (Start the video with this):**
> *"Hi everyone, I'm proud to present our Luxury Watch Tokenization platform. We are bridging the gap between high-end physical assets and decentralized finance. By using Chainlink CRE and CCIP, we allow investors to buy, sell, and trade verified fractional ownership of luxury watches with full on-chain transparency. Let's dive in!"*

---


## 1. Environment Setup

Verify your `.env` values (`nano .env`):
```env
CRE_ETH_PRIVATE_KEY=0x... # High-level admin key
PINATA_JWT=eyJhbG...      # Your Pinata API Key
SEPOLIA_RPC=https://ethereum-sepolia-rpc.publicnode.com
```

Apply to your session:
```bash
source .env
export PRIVATE_KEY=$CRE_ETH_PRIVATE_KEY
export SEPOLIA_RPC=https://ethereum-sepolia-rpc.publicnode.com
```

---

## 2. Deploy Contracts

Deploy the registry and the CRE listener.

> **🎙️ Script:** *"We're starting our demo by deploying the core infrastructure. First, we deploy the `LuxuryWatch` registry, which handles our fractional ownership logic. Next, we deploy the `WatchMintingConsumer`. This is our Chainlink CRE listener that bridges off-chain verification with on-chain execution, ensuring only verified assets are tokenized."*

### A. Deploy LuxuryWatch (The Registry)
```bash
forge create contracts/LuxuryWatch.sol:LuxuryWatch \
  --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast
```
**Copy the address:** `export LUXURY_WATCH=<address>`

### B. Deploy WatchMintingConsumer (The CRE Listener)
```bash
forge create contracts/WatchMintingConsumer.sol:WatchMintingConsumer \
  --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast \
  --constructor-args $LUXURY_WATCH "0x0000000000000000000000000000000000000000" "0x64756d6d790000000000"
```
**Copy the address:** `export WATCH_CONSUMER=<address>`


---

## 3. Link Contracts to Scripts & CRE

1. Update `luxury-watch-workflow/config.json`:
   - Set `luxuryWatchAddress` to `$LUXURY_WATCH`
   - Set `consumerAddress` to `$WATCH_CONSUMER`
   - Ensure `gasLimit` is `"1000000"`.

2. Update `.env`:
```env
LUXURY_WATCH_SEPOLIA=<LUXURY_WATCH_ADDR>
WATCH_CONSUMER_SEPOLIA=<WATCH_CONSUMER_ADDR>
```

3. Re-build the workflow:
```bash
cre workflow build luxury-watch-workflow
```

---

## 4. The Magic Command: Auto-Mint & IPFS Sync 🚀

Run the bundled script to mint and upload metadata in one go:

> **🎙️ Script:** *"Now for the magic. When a physical watch is verified off-chain, we run our automated minting script. This triggers a Chainlink CRE workflow that doesn't just mint the token—it automatically generates high-fidelity metadata, uploads it to IPFS via Pinata, and syncs the CID back to our contract. This creates a seamless, tamper-proof bridge between the physical asset and its digital twin."*

```bash
./scripts/mint-watch.sh
```
*Press Enter for defaults (Rolex, 100 fractions, 0.35 ETH price).*

**Watch what happens:**
1. ⛓️ **CRE Mints:** Triggered on-chain via Chainlink.
2. 📂 **Pinata Syncs:** Reads the mint event, builds JSONs for ALL tokens, and uploads a folder.
3. 🎯 **URI Linked:** Calls `setBaseURI` automatically so `uri(id)` returns `ipfs://.../id.json`.


---

## 5. LIVE DEMO: Buying & Trading (Terminal Interactivity)

Simulate a second user (Buyer) interacting with your platform from the terminal.

> **🎙️ Script:** *"With our asset tokenized, let's look at the marketplace. As an admin, I'll list these fractions for sale. Now, a buyer can instantly purchase fractional ownership using ETH. But we go a step further: our platform supports true peer-to-peer trading. Any holder can set their own secondary market price and enable global listings, unlocking liquidity for luxury assets that was previously impossible."*

### **Setup Accounts**
Open a terminal and set your variables. You'll need a second private key (`BUYER_KEY`) for a second wallet.
```bash
export LUXURY_WATCH="<address>"
export ADMIN_KEY="<first_key>"
export BUYER_KEY="<second_key>"
export BUYER_ADDR="<second_address>"
```

### **Scenario A: Admin Listing the Asset**
Because the tokens are minted to the `WatchMintingConsumer` contract, the Admin (you) must tell that contract to list them for sale on the registry.
```bash
# 1. Enable Sale for Token ID 0 (Proxy call via Consumer)
cast send $WATCH_CONSUMER "updateWatchSaleStatus(uint256,bool)" 0 true --private-key $ADMIN_KEY --rpc-url $SEPOLIA_RPC

# 2. Check the price (calculated by fractions * price_per_fraction)
# 10 fractions * 0.35 ETH = 3.5 ETH
cast call $LUXURY_WATCH "SetWatchPrice(uint256,uint256)" 0 10 --rpc-url $SEPOLIA_RPC
```


### **Scenario B: Buyer "Purchasing" Fractions**
The Buyer sends ETH and receives the fractions automatically.
```bash
# Buy 10 fractions (sending 3.5 ETH)
cast send $LUXURY_WATCH "TransferTokenWatchFromVault(uint256,uint256)" 0 10 \
  --value 3.5ether --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC
```

### **Scenario C: Peer-to-Peer Trading**
Now the Buyer wants to sell to someone else at a custom price.
```bash
# 1. Buyer sets a custom price (e.g., 0.5 ETH per fraction)
cast send $LUXURY_WATCH "setFractionPrice(uint256,uint256)" 0 500000000000000000 \
  --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC

# 2. Buyer enables their listing
cast send $LUXURY_WATCH "UpdateChoice(uint256,bool)" 0 true \
  --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC
```


---

## 6. Validation (Judges View) 🔍

Prove the data is decentralized and accurate:

> **🎙️ Script:** *"Finally, let's verify the transparency. We can query the contract to see the immutable IPFS metadata link and verify the buyer's new balance. This proves that our system is not just automated, but fully decentralized and verifiable on-chain. Thanks for watching!"*

**Look up IPFS Metadata:**
```bash
cast call $LUXURY_WATCH "uri(uint256)" 0 --rpc-url $SEPOLIA_RPC --decode "(string)"
```
*(Result: `ipfs://baf.../luxury-watch-metadata/0.json`)*

**Check Buyer Balance:**
```bash
cast call $LUXURY_WATCH "balanceOf(address,uint256)" $BUYER_ADDR 0 --rpc-url $SEPOLIA_RPC
```
*(Result: `10`)*

