#!/bin/bash

# =============================================================================
# Automated Minting & IPFS Sync Script
# Run from the project root: ./scripts/mint-watch.sh
# =============================================================================

echo "═══════════════════════════════════════════════════════"
echo "  ⌚ Luxury Watch Auto-Minter & IPFS Syncer"
echo "═══════════════════════════════════════════════════════"

# 1. Source the environment variables first
if [ -f .env ]; then
    source .env
fi

# 2. Interactive Account Selection
echo -e "\n👤 Select Account for this Mint:"
echo "1) Admin Account (Default from .env)"
if [ ! -z "$BUYER_KEY" ]; then 
    echo "2) Buyer Account (Detected from terminal: BUYER_KEY)"
fi
echo "3) Custom Private Key (Paste manually)"
read -p "Choice (1-3, default 1): " accountChoice
accountChoice=${accountChoice:-1}

case $accountChoice in
    2)
        if [ -z "$BUYER_KEY" ]; then echo -e "❌ ERROR: BUYER_KEY not set."; exit 1; fi
        ACTUAL_KEY=$BUYER_KEY
        echo -e "✅ Using Buyer account."
        ;;
    3)
        read -s -p "Paste the Private Key (0x...): " manualKey
        echo -e "\n"
        ACTUAL_KEY=$manualKey
        echo -e "✅ Using custom account."
        ;;
    *)
        ACTUAL_KEY=$CRE_ETH_PRIVATE_KEY
        echo -e "✅ Using Admin account."
        ;;
esac

if [ -z "$ACTUAL_KEY" ]; then echo -e "❌ ERROR: No private key found. Check your .env or entry."; exit 1; fi

# 3. Resolve actual address for ownership
ACTUAL_ADDRESS=$(cast wallet address --private-key $ACTUAL_KEY)
echo -e "📍 Wallet Address: $ACTUAL_ADDRESS"

# 4. Prompt for watch details
read -p "Watch Brand (default: Rolex): " brand
brand=${brand:-Rolex}

read -p "Watch Model (default: Daytona): " model
model=${model:-Daytona}

read -p "Serial Number (default: RLX-116500-ABC123): " serial
serial=${serial:-RLX-116500-ABC123}

read -p "Total Fractions (default: 100): " fractions
fractions=${fractions:-100}

read -p "Price per fraction in WEI (default: 350000000000000000): " priceWei
priceWei=${priceWei:-350000000000000000}

# 4. Update the JSON payload dynamically
cat <<EOF > luxury-watch-workflow/http_trigger_payload.json
{
    "ownerAddress": "$ACTUAL_ADDRESS",
    "watchBrand": "$brand",
    "watchModel": "$model",
    "watchSerial": "$serial",
    "totalFractions": $fractions,
    "pricePerFractionWei": "$priceWei",
    "appraisalSource": "WatchCert Labs"
}
EOF

echo -e "\n✅ Updated luxury-watch-workflow/http_trigger_payload.json"

export PRIVATE_KEY=${ACTUAL_KEY}
export CRE_PROJECT_ROOT=$(pwd)

echo -e "\n🚀 STEP 1: Minting the watch via CRE workflow...\n"

# 5. Simulate the CRE workflow
cre workflow simulate luxury-watch-workflow \
  --target local-simulation \
  --broadcast \
  --trigger-index 0 \
  --non-interactive \
  --http-payload @$CRE_PROJECT_ROOT/luxury-watch-workflow/http_trigger_payload.json

# 6. Check if it succeeded before running Pinata
if [ $? -eq 0 ]; then
    echo -e "\n🎉 Minting successful!"
    echo -e "☁️  STEP 2: Auto-syncing IPFS metadata via Pinata...\n"
    
    # Run the Pinata node script
    node scripts/pinata-upload.js
else
    echo -e "\n❌ CRE minting failed. Halting before IPFS upload."
fi
