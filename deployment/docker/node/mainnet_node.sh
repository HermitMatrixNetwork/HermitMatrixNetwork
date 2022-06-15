#!/usr/bin/env bash
set -euv

export GHM_SGX_STORAGE=/opt/ghm/.sgx_ghms
export GHM_ENCLAVE_DIR=/usr/lib

FORCE_REGISTER=${FORCE_REGISTER:-}
FORCE_SYNC=${FORCE_SYNC:-}

CHAINID="${CHAINID:-secret-4}"
MONIKER="${MONIKER:-default}"
REGISTRATION_SERVICE="${REGISTRATION_SERVICE:-https://mainnet-register.scrtlabs.com/api/registernode}"
STATE_SYNC1="${STATE_SYNC1:-http://peer.node.scrtlabs.com:26657}"
STATE_SYNC2="${STATE_SYNC2:-${STATE_SYNC1:-http://peer.node.scrtlabs.com:26657}}"

file=/opt/ghm/.sgx_ghms/consensus_seed.sealed
if [ ! -z "$FORCE_REGISTER" ] || [ ! -e "$file" ];
then
  ghmd auto-register --reset --registration-service $REGISTRATION_SERVICE
fi

file=/root/.ghmd/data/blockstore.db/MANIFEST-000000
if [ ! -z "$FORCE_SYNC" ] || [ ! -e "$file" ];
then

  echo "Resetting or initializing node"

  rm -rf /root/.ghmd/* || true

  mkdir -p /root/.ghmd/.node
  ghmd config chain-id "$CHAINID"

  ghmd init "$MONIKER" --chain-id "$CHAINID"

  echo "Initialized chain: $CHAINID with node moniker: $MONIKER"

  cp /root/genesis.json /root/.ghmd/config/genesis.json

  # Open RPC port to all interfaces
  perl -i -pe 's/laddr = .+?26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' /root/.ghmd/config/config.toml

  if [ ! -z "$STATE_SYNC1" ] && [ ! -z "$STATE_SYNC2" ];
  then

    echo "Syncing with state sync"

    LATEST_HEIGHT=$(curl -s $STATE_SYNC1/block | jq -r .result.block.header.height); \
    BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
    TRUST_HASH=$(curl -s "$STATE_SYNC1/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

    echo "State sync node: $STATE_SYNC1,$STATE_SYNC2"
    echo "Trust hash: $TRUST_HASH; Block height: $BLOCK_HEIGHT"

    # enable state sync (this is the only line in the config that uses enable = false. This could change and break everything
    perl -i -pe 's/enable = false/enable = true/' ~/.ghmd/config/config.toml

    sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
    s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$STATE_SYNC1,$STATE_SYNC2\"| ; \
    s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
    s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.ghmd/config/config.toml
  else
    echo "Syncing with block sync"
  fi
fi
ghmd start
