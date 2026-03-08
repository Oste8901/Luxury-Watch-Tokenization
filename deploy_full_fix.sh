#!/bin/bash
# deploy_full_fix.sh
FORGE="/home/sman_olla/.foundry/bin/forge"
RPC="https://ethereum-sepolia-rpc.publicnode.com"
PK="0x9abb426adf9e39a81f89b80e49e2556731d00ce8e1009c5320b846ae172fc0e5"

echo "🧹 Cleaning cache..."
$FORGE clean

echo "🚀 Deploying Registry..."
REG_OUT=$($FORGE create contracts/LuxuryWatch.sol:LuxuryWatch --rpc-url $RPC --private-key $PK --broadcast)
echo "$REG_OUT" > reg_deploy_log.txt
REG_ADDR=$(echo "$REG_OUT" | grep "Deployed to: " | awk '{print $NF}')

if [ -z "$REG_ADDR" ]; then
    echo "❌ Failed to capture Registry Address!"
    exit 1
fi

echo "✅ Registry Deployed to: $REG_ADDR"

echo "🚀 Deploying Consumer..."
CONS_OUT=$($FORGE create contracts/WatchMintingConsumer.sol:WatchMintingConsumer --rpc-url $RPC --private-key $PK --broadcast --constructor-args $REG_ADDR 0x0000000000000000000000000000000000000000 0x64756d6d790000000000)
echo "$CONS_OUT" > cons_deploy_log.txt
CONS_ADDR=$(echo "$CONS_OUT" | grep "Deployed to: " | awk '{print $NF}')

if [ -z "$CONS_ADDR" ]; then
    echo "❌ Failed to capture Consumer Address!"
    exit 1
fi

echo "✅ Consumer Deployed to: $CONS_ADDR"

# Save to a clean file we can read from Windows
echo "REGISTRY=$REG_ADDR" > final_addresses.txt
echo "CONSUMER=$CONS_ADDR" >> final_addresses.txt

echo "🏁 Deployment Complete!"
