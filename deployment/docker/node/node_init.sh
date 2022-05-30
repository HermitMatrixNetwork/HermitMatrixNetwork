#!/usr/bin/env bash
set -euv

# REGISTRATION_SERVICE=
# export RPC_URL="bootstrap:26657"
# export CHAINID="ghmdev-1"
# export PERSISTENT_PEERS="115aa0a629f5d70dd1d464bc7e42799e00f4edae@bootstrap:26656"

# init the node
# rm -rf ~/.secret*

# rm -rf ~/.ghmd
file=/root/.ghmd/config/attestation_cert.der
if [ ! -e "$file" ]
then
  rm -rf ~/.ghmd/* || true

  mkdir -p /root/.ghmd/.node
  # ghmd config keyring-backend test
  ghmd config node tcp://"$RPC_URL"
  ghmd config chain-id "$CHAINID"
#  export SECRET_NETWORK_CHAIN_ID=$CHAINID
#  export SECRET_NETWORK_KEYRING_BACKEND=test
  # ghmd init "$(hostname)" --chain-id enigma-testnet || true

  ghmd init "$MONIKER" --chain-id "$CHAINID"

  # cp /tmp/.ghmd/keyring-test /root/.ghmd/ -r

  echo "Initializing chain: $CHAINID with node moniker: $(hostname)"

  sed -i 's/persistent_peers = ""/persistent_peers = "'"$PERSISTENT_PEERS"'"/g' ~/.ghmd/config/config.toml
  echo "Set persistent_peers: $PERSISTENT_PEERS"

  # Open RPC port to all interfaces
  perl -i -pe 's/laddr = .+?26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' ~/.ghmd/config/config.toml

  # Open P2P port to all interfaces
  perl -i -pe 's/laddr = .+?26656"/laddr = "tcp:\/\/0.0.0.0:26656"/' ~/.ghmd/config/config.toml

  echo "Waiting for bootstrap to start..."
  sleep 10

  ghmd init-enclave

  PUBLIC_KEY=$(ghmd parse /opt/ghm/.sgx_ghms/attestation_cert.der 2> /dev/null | cut -c 3- )

  echo "Public key: $(ghmd parse /opt/ghm/.sgx_ghms/attestation_cert.der 2> /dev/null | cut -c 3- )"

  cp /opt/ghm/.sgx_ghms/attestation_cert.der /root/.ghmd/config/

  openssl base64 -A -in attestation_cert.der -out b64_cert
  # ghmd tx register auth attestation_cert.der --from a --gas-prices 0.25uscrt -y

  curl -G --data-urlencode "cert=$(cat b64_cert)" http://"$REGISTRATION_SERVICE"/register

  sleep 20

  SEED=$(ghmd q register seed "$PUBLIC_KEY"  2> /dev/null | cut -c 3-)
  echo "SEED: $SEED"

  ghmd q register secret-network-params 2> /dev/null

  ghmd configure-secret node-master-cert.der "$SEED"

  curl http://"$RPC_URL"/genesis | jq -r .result.genesis > /root/.ghmd/config/genesis.json

  echo "Downloaded genesis file from $RPC_URL "

  ghmd validate-genesis

  ghmd config node tcp://localhost:26657

fi
ghmd start
