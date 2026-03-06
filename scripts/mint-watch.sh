#!/bin/bash

# =============================================================================
# Automated Minting & IPFS Sync Script
# Run from the project root: ./scripts/mint-watch.sh
# =============================================================================

echo "═══════════════════════════════════════════════════════"
echo "  ⌚ Luxury Watch Auto-Minter & IPFS Syncer"
echo "═══════════════════════════════════════════════════════"

# Prompt for watch details
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

# 1. Update the JSON payload dynamically
cat <<EOF > luxury-watch-workflow/http_trigger_payload.json
{
    "watchBrand": "$brand",
    "watchModel": "$model",
    "watchSerial": "$serial",
    "totalFractions": $fractions,
    "pricePerFractionWei": "$priceWei",
    "appraisalSource": "WatchCert Labs"
}
EOF

echo -e "\n✅ Updated luxury-watch-workflow/http_trigger_payload.json"

# 2. Source the environment variables
source .env
export PRIVATE_KEY=$CRE_ETH_PRIVATE_KEY
export CRE_PROJECT_ROOT=$(pwd)

echo -e "\n🚀 STEP 1: Minting the watch via CRE workflow...\n"

# 3. Simulate the CRE workflow
cre workflow simulate luxury-watch-workflow \
  --target local-simulation \
  --broadcast \
  --trigger-index 0 \
  --non-interactive \
  --http-payload @$CRE_PROJECT_ROOT/luxury-watch-workflow/http_trigger_payload.json

# 4. Check if it succeeded before running Pinata
if [ $? -eq 0 ]; then
    echo -e "\n🎉 Minting successful!"
    echo -e "☁️  STEP 2: Auto-syncing IPFS metadata via Pinata...\n"
    
    # Run the Pinata node script
    node scripts/pinata-upload.js
else
    echo -e "\n❌ CRE minting failed. Halting before IPFS upload."
fi
