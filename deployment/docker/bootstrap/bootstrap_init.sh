#!/bin/bash

file=~/.ghmd/config/genesis.json
if [ ! -e "$file" ]; then
  # init the node
  rm -rf ~/.ghmd/*
  rm -rf /opt/ghm/.sgx_ghms/*

  if [ -z "${CHAINID}" ]; then
    chain_id="$CHAINID"
  else
    chain_id="supernova-1"
  fi

  mkdir -p ./.sgx_secrets
  ghmd config chain-id "$chain_id"
  ghmd config keyring-backend test

  # export SECRET_NETWORK_CHAIN_ID=ghmdev-1
  # export SECRET_NETWORK_KEYRING_BACKEND=test
  ghmd init banana --chain-id "$chain_id"


  cp ~/node_key.json ~/.ghmd/config/node_key.json
  perl -i -pe 's/"stake"/"uscrt"/g' ~/.ghmd/config/genesis.json
  perl -i -pe 's/"172800000000000"/"90000000000"/g' ~/.ghmd/config/genesis.json # voting period 2 days -> 90 seconds

  ghmd keys add a
  ghmd keys add b
  ghmd keys add c
  ghmd keys add d

  ghmd add-genesis-account "$(ghmd keys show -a a)" 1000000000000000000uscrt
#  ghmd add-genesis-account "$(ghmd keys show -a b)" 1000000000000000000uscrt
#  ghmd add-genesis-account "$(ghmd keys show -a c)" 1000000000000000000uscrt
#  ghmd add-genesis-account "$(ghmd keys show -a d)" 1000000000000000000uscrt


  ghmd gentx a 1000000uscrt --chain-id "$chain_id"
#  ghmd gentx b 1000000uscrt --keyring-backend test
#  ghmd gentx c 1000000uscrt --keyring-backend test
#  ghmd gentx d 1000000uscrt --keyring-backend test

  ghmd collect-gentxs
  ghmd validate-genesis

#  ghmd init-enclave
  ghmd init-bootstrap
#  cp new_node_seed_exchange_keypair.sealed .sgx_secrets
  ghmd validate-genesis

  perl -i -pe 's/max_subscription_clients.+/max_subscription_clients = 100/' ~/.ghmd/config/config.toml
  perl -i -pe 's/max_subscriptions_per_client.+/max_subscriptions_per_client = 50/' ~/.ghmd/config/config.toml
fi

lcp --proxyUrl http://localhost:1317 --port 1337 --proxyPartial '' &

# sleep infinity
source /opt/sgxsdk/environment && RUST_BACKTRACE=1 ghmd start --rpc.laddr tcp://0.0.0.0:26657 --bootstrap