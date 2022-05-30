#!/usr/bin/env bash

set -euvo pipefail

# init the node
# rm -rf ~/.secret*
#ghmcli config chain-id enigma-testnet
#ghmcli config output json
#ghmcli config indent true
#ghmcli config trust-node true
#ghmcli config keyring-backend test
rm -rf ~/.ghmd

mkdir -p /root/.ghmd/.node
ghmd config keyring-backend test
ghmd config node tcp://bootstrap:26657
ghmd config chain-id ghmdev-1

ghmd init "$(hostname)" --chain-id ghmdev-1 || true

PERSISTENT_PEERS="115aa0a629f5d70dd1d464bc7e42799e00f4edae@bootstrap:26656"

sed -i 's/persistent_peers = ""/persistent_peers = "'$PERSISTENT_PEERS'"/g' ~/.ghmd/config/config.toml
echo "Set persistent_peers: $PERSISTENT_PEERS"

echo "Waiting for bootstrap to start..."
sleep 20

cp /tmp/.ghmd/keyring-test /root/.ghmd/ -r

ghmd init-enclave

PUBLIC_KEY=$(ghmd parse /opt/ghm/.sgx_ghms/attestation_cert.der 2> /dev/null | cut -c 3- )

echo "Public key: $(ghmd parse /opt/ghm/.sgx_ghms/attestation_cert.der 2> /dev/null | cut -c 3- )"

ghmd tx register auth /opt/ghm/.sgx_ghms/attestation_cert.der -y --from a --gas-prices 0.25uscrt

sleep 10

SEED=$(ghmd q register seed "$PUBLIC_KEY" 2> /dev/null | cut -c 3-)
echo "SEED: $SEED"

ghmd q register secret-network-params 2> /dev/null

ghmd configure-secret node-master-cert.der "$SEED"

cp /tmp/.ghmd/config/genesis.json /root/.ghmd/config/genesis.json

ghmd validate-genesis

ghmd config node tcp://localhost:26657

RUST_BACKTRACE=1 ghmd start &

./wasmi-sgx-test.sh
