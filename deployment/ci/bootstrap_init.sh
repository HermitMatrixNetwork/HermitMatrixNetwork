#!/bin/bash

set -euvo pipefail

rm -rf ~/.ghmd/*
rm -rf /opt/ghm/.sgx_ghms/*

ghmd config chain-id ghmdev
ghmd config keyring-backend test

ghmd init banana --chain-id ghmdev

cp ~/node_key.json ~/.ghmd/config/node_key.json
perl -i -pe 's/"stake"/ "ughm"/g' ~/.ghmd/config/genesis.json

ghmd keys add a
ghmd keys add b
ghmd keys add c
ghmd keys add d

ghmd add-genesis-account "$(ghmd keys show -a a)" 100000000ughm

ghmd gentx a 10000000ughm --chain-id ghmdev --gas-prices 0.25ughm

ghmd collect-gentxs
ghmd validate-genesis

ghmd init-bootstrap
ghmd validate-genesis

source /opt/sgxsdk/environment && RUST_BACKTRACE=1 ghmd start --rpc.laddr tcp://0.0.0.0:26657 --bootstrap
