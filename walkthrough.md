# ⌚ Luxury Watch Tokenization — Two-Way Economy Walkthrough

This guide demonstrates a **fully decentralized marketplace** where both the **Admin** and the **Buyer** act as creators, investors, and sellers.

---

## 🏗️ 1. Setup & Personas
Ensure your environment is synchronized with the latest deployment:
*   **Admin**: `0x6b84...` (Contract Owner)
*   **Buyer**: `0x5F11...` (Secondary Creator)

```bash
source .env
# Set Helper Variables
export LUXURY_WATCH=${LUXURY_WATCH_SEPOLIA}
export WATCH_CONSUMER=${WATCH_CONSUMER_SEPOLIA}
```

---

## 🚀 2. Scenario A: Admin is the Creator
*The Admin mints a Rolex and the Buyer invests.*

### **Step 1: Admin Mints (Rolex Daytona)**
Run `./scripts/mint-watch.sh` and choose **Choice 1 (Admin)**.

### **Step 1.5: Admin Enables Primary Sale**
To list the watch for sale, the Creator (Admin) must call `UpdateChoice` on the **Registry**. 
*(Note: We call the Registry directly because the tokens are in the Admin's wallet.)*
```bash
cast send $LUXURY_WATCH "UpdateChoice(uint256,bool)" 0 true \
  --private-key $ADMIN_KEY --rpc-url $SEPOLIA_RPC
```

### **Step 2: Buyer Purchases from Admin's Vault**
```bash
# Buyer purchases 10 fractions (0.1 ETH total)
cast send $LUXURY_WATCH "TransferTokenWatchFromVault(uint256,uint256)" 0 10 \
  --value 0.1ether --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC
```

---

## 🌟 3. Scenario B: Buyer is the Creator (The "Two-Way" Magic)
*The Buyer mints their own watch and the Admin invests. This proves decentralization.*

### **Step 1: Buyer Mints (Patek Philippe)**
Run `./scripts/mint-watch.sh` and choose **Choice 2 (Buyer)**.

### **Step 1.5: Buyer Enables Primary Sale**
The Buyer (as the creator of Token #1) enables their own sale.
```bash
cast send $LUXURY_WATCH "UpdateChoice(uint256,bool)" 1 true \
  --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC
```

### **Step 2: Admin Purchases from Buyer's Vault**
```bash
# Admin purchases 5 fractions (0.05 ETH total)
cast send $LUXURY_WATCH "TransferTokenWatchFromVault(uint256,uint256)" 1 5 \
  --value 0.05ether --private-key $ADMIN_KEY --rpc-url $SEPOLIA_RPC
```

---

## 📈 4. Scenario C: Secondary Market (P2P Trading)
*The Buyer decides to list their Rolex fractions (Token #0) for sale.*

```bash
# 1. Buyer sets custom price for Rolex (Token #0) to 0.5 ETH
cast send $LUXURY_WATCH "setFractionPrice(uint256,uint256)" 0 500000000000000000 \
  --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC

# 2. Buyer enables their PERSONAL secondary listing
cast send $LUXURY_WATCH "UpdateChoice(uint256,bool)" 0 true \
  --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC

# 3. Admin buys back from the Buyer (Secondary Transfer)
cast send $LUXURY_WATCH "TransferTokenWatchfromUser(address,uint256,uint256)" \
  $BUYER_ADDR 0 2 --value 1ether --private-key $ADMIN_KEY --rpc-url $SEPOLIA_RPC
```

---
### **Judges View (On-Chain Proof)**
```bash
# Verify Buyer is owner of Token #1 creator
cast call $LUXURY_WATCH "watch_creator(uint256)" 1 --rpc-url $SEPOLIA_RPC

# Verify Sale Status (checks the Buyer's listing)
cast call $LUXURY_WATCH "isForSale(uint256,address)" 1 $BUYER_ADDR --rpc-url $SEPOLIA_RPC
```

---

## 📦 5. Scenario D: Batch Trading (Bulk Operations)
*Showcase the ability to buy multiple watches in a single transaction.*

### **1. Batch Buy from Vault**
Buy 10 fractions of Token #0 and 5 fractions of Token #1 from the Admin in one go.
```bash
# Total cost: (10 + 5) * 0.01 ETH = 0.15 ETH
cast send $LUXURY_WATCH "TransferTokenWatchBatchFromVault(address,uint256[],uint256[])" \
  $(cast wallet address --private-key $ADMIN_KEY) "[0,1]" "[10,5]" \
  --value 0.15ether --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC
```

### **2. Batch Buy from User (Secondary)**
If the Admin has listed multiple items, the Buyer can sweep them in one call.
```bash
# Ensure Admin has listed these first!
cast send $LUXURY_WATCH "TransferTokenWatchBatchFromUser(address,uint256[],uint256[])" \
  $(cast wallet address --private-key $ADMIN_KEY) "[0,1]" "[2,1]" \
  --value 0.03ether --private-key $BUYER_KEY --rpc-url $SEPOLIA_RPC
```

---

## 🎉 Demo Complete!
You have successfully demonstrated:
1. **Multi-User Creator Flow**: Both Admin and Buyer minting their own watches.
2. **Instant Creator Payouts**: Real-time ETH transfers to the creator's wallet.
3. **P2P Marketplace**: Peer-to-peer secondary trading at custom prices.

**Your platform is now ready for submission. Good luck!** 🏆🔥⌚
