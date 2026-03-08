#!/bin/bash
export FORGE="/home/sman_olla/.foundry/bin/forge"
export RPC="https://ethereum-sepolia-rpc.publicnode.com"
export PK="0x9abb426adf9e39a81f89b80e49e2556731d00ce8e1009c5320b846ae172fc0e5"
export REGISTRY="0x9A09D16EaFaD5C579CE51bbe30BE78C5bf"

$FORGE create contracts/WatchMintingConsumer.sol:WatchMintingConsumer \
  --rpc-url $RPC \
  --private-key $PK \
  --broadcast \
  --constructor-args $REGISTRY 0x0000000000000000000000000000000000000000 0x64756d6d790000000000
