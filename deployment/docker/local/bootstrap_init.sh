#!/bin/bash
set -euo pipefail

file=~/.ghmd/config/genesis.json
if [ ! -e "$file" ]
then
  # init the node
  rm -rf ~/.ghmd/*
  rm -rf ~/.ghmcli/*
  rm -rf ~/.sgx_secrets/*
  ghmcli config chain-id enigma-pub-testnet-3
  ghmcli config output json
#  ghmcli config indent true
#  ghmcli config trust-node true
  ghmcli config keyring-backend test

  ghmd init banana --chain-id enigma-pub-testnet-3

  cp ~/node_key.json ~/.ghmd/config/node_key.json

  perl -i -pe 's/"stake"/"uscrt"/g' ~/.ghmd/config/genesis.json
  ghmcli keys add a
  ghmcli keys add b
  ghmcli keys add c
  ghmcli keys add d

  ghmd add-genesis-account "$(ghmcli keys show -a a)" 1000000000000000000uscrt
#  ghmd add-genesis-account "$(ghmcli keys show -a b)" 1000000000000000000uscrt
#  ghmd add-genesis-account "$(ghmcli keys show -a c)" 1000000000000000000uscrt
#  ghmd add-genesis-account "$(ghmcli keys show -a d)" 1000000000000000000uscrt


  ghmd gentx a 1000000uscrt --keyring-backend test --chain-id enigma-pub-testnet-3
  # These fail for some reason:
  # ghmd gentx --name b --keyring-backend test --amount 1000000uscrt
  # ghmd gentx --name c --keyring-backend test --amount 1000000uscrt
  # ghmd gentx --name d --keyring-backend test --amount 1000000uscrt

  ghmd collect-gentxs
  ghmd validate-genesis

  ghmd init-bootstrap
  ghmd validate-genesis
fi

# sleep infinity
source /opt/sgxsdk/environment && RUST_BACKTRACE=1 ghmd start --rpc.laddr tcp://0.0.0.0:26657 --bootstrap
