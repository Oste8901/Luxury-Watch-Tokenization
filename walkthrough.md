# Luxury Watch Tokenization — Ultimate Hackathon Walkthrough

This guide covers everything you need to confidently run your luxury watch tokenization demo. From deploying contracts to automatically minting the watch on-chain via the built-in Chainlink CRE integration and then interacting with it from the terminal for a "Live Buy" demo.

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
