#!/usr/bin/env bash

set -euvo pipefail

# init the node
# rm -rf ~/.secret*
#ghmcli config chain-id enigma-testnet
#ghmcli config output json
#ghmcli config indent true
#ghmcli config trust-node true
#ghmcli config keyring-backend test
# rm -rf ~/.ghmd

mkdir -p /root/.ghmd/.node
ghmd config keyring-backend test
ghmd config node http://bootstrap:26657
ghmd config chain-id enigma-pub-testnet-3

mkdir -p /root/.ghmd/.node

ghmd init "$(hostname)" --chain-id enigma-pub-testnet-3 || true

PERSISTENT_PEERS=115aa0a629f5d70dd1d464bc7e42799e00f4edae@bootstrap:26656

sed -i 's/persistent_peers = ""/persistent_peers = "'$PERSISTENT_PEERS'"/g' ~/.ghmd/config/config.toml
sed -i 's/trust_period = "168h0m0s"/trust_period = "168h"/g' ~/.ghmd/config/config.toml
echo "Set persistent_peers: $PERSISTENT_PEERS"

echo "Waiting for bootstrap to start..."
sleep 20

ghmcli q block 1

cp /tmp/.ghmd/keyring-test /root/.ghmd/ -r

# MASTER_KEY="$(ghmcli q register secret-network-params 2> /dev/null | cut -c 3- )"

#echo "Master key: $MASTER_KEY"

ghmd init-enclave --reset

PUBLIC_KEY=$(ghmd parse /opt/ghm/.sgx_ghms/attestation_cert.der | cut -c 3- )

echo "Public key: $PUBLIC_KEY"

ghmd parse /opt/ghm/.sgx_ghms/attestation_cert.der
cat /opt/ghm/.sgx_ghms/attestation_cert.der
tx_hash="$(ghmcli tx register auth /opt/ghm/.sgx_ghms/attestation_cert.der -y --from a --gas-prices 0.25uscrt | jq -r '.txhash')"

#ghmcli q tx "$tx_hash"
sleep 15
ghmcli q tx "$tx_hash"

SEED="$(ghmcli q register seed "$PUBLIC_KEY" | cut -c 3-)"
echo "SEED: $SEED"
#exit

ghmcli q register secret-network-params

ghmd configure-secret node-master-cert.der "$SEED"

cp /tmp/.ghmd/config/genesis.json /root/.ghmd/config/genesis.json

ghmd validate-genesis

RUST_BACKTRACE=1 ghmd start --rpc.laddr tcp://0.0.0.0:26657

# ./wasmi-sgx-test.sh
