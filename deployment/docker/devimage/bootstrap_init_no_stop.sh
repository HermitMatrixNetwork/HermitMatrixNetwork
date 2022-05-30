#!/bin/bash

file=~/.ghmd/config/genesis.json
if [ ! -e "$file" ]
then
  # init the node
  rm -rf ~/.ghmd/*
  rm -rf /opt/ghm/.sgx_ghms/*

  if [ -z "${CHAINID}" ]; then
    chain_id="$CHAINID"
  else
    chain_id="ghmdev-1"
  fi

  mkdir -p ./.sgx_secrets
  ghmd config chain-id "$chain_id"
  ghmd config output json
  ghmd config keyring-backend test

  # export SECRET_NETWORK_CHAIN_ID=ghmdev-1
  # export SECRET_NETWORK_KEYRING_BACKEND=test
  ghmd init banana --chain-id "$chain_id"


  cp ~/node_key.json ~/.ghmd/config/node_key.json
  perl -i -pe 's/"stake"/"uscrt"/g' ~/.ghmd/config/genesis.json
  perl -i -pe 's/"172800s"/"90s"/g' ~/.ghmd/config/genesis.json # voting period 2 days -> 90 seconds

  perl -i -pe 's/enable-unsafe-cors = false/enable-unsafe-cors = true/g' ~/.ghmd/config/app.toml # enable cors

  a_mnemonic="grant rice replace explain federal release fix clever romance raise often wild taxi quarter soccer fiber love must tape steak together observe swap guitar"
  b_mnemonic="jelly shadow frog dirt dragon use armed praise universe win jungle close inmate rain oil canvas beauty pioneer chef soccer icon dizzy thunder meadow"
  c_mnemonic="chair love bleak wonder skirt permit say assist aunt credit roast size obtain minute throw sand usual age smart exact enough room shadow charge"
  d_mnemonic="word twist toast cloth movie predict advance crumble escape whale sail such angry muffin balcony keen move employ cook valve hurt glimpse breeze brick"
  
  echo $a_mnemonic | ghmd keys add a --recover
  echo $b_mnemonic | ghmd keys add b --recover
  echo $c_mnemonic | ghmd keys add c --recover
  echo $d_mnemonic | ghmd keys add d --recover

  ghmd add-genesis-account "$(ghmd keys show -a a)" 1000000000000000000uscrt
  ghmd add-genesis-account "$(ghmd keys show -a b)" 1000000000000000000uscrt
  ghmd add-genesis-account "$(ghmd keys show -a c)" 1000000000000000000uscrt
  ghmd add-genesis-account "$(ghmd keys show -a d)" 1000000000000000000uscrt


  ghmd gentx a 1000000uscrt --chain-id "$chain_id"
  ghmd gentx b 1000000uscrt --chain-id "$chain_id"
  ghmd gentx c 1000000uscrt --chain-id "$chain_id"
  ghmd gentx d 1000000uscrt --chain-id "$chain_id"

  ghmd collect-gentxs
  ghmd validate-genesis

#  ghmd init-enclave
  ghmd init-bootstrap
#  cp new_node_seed_exchange_keypair.sealed .sgx_secrets
  ghmd validate-genesis
fi

# Setup CORS for LCD & gRPC-web
perl -i -pe 's;address = "tcp://0.0.0.0:1317";address = "tcp://0.0.0.0:1316";' .ghmd/config/app.toml
perl -i -pe 's/enable-unsafe-cors = false/enable-unsafe-cors = true/' .ghmd/config/app.toml
lcp --proxyUrl http://localhost:1316 --port 1317 --proxyPartial '' &

# Setup faucet
gunicorn --bind 0.0.0.0:5000 svc &

# Setup ghmcli
cp $(which ghmd) $(dirname $(which ghmd))/ghmcli

source /opt/sgxsdk/environment && RUST_BACKTRACE=1 ghmd start --rpc.laddr tcp://0.0.0.0:26657 --bootstrap

