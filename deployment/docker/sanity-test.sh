#!/bin/bash

set -euvx

function wait_for_tx () {
    until (ghmd q tx "$1" --output json)
    do
        echo "$2"
        sleep 1
    done
}

# # init the node
# rm -rf ./.sgx_secrets ~/.sgx_secrets *.der ~/*.der
# mkdir -p ./.sgx_secrets ~/.sgx_secrets

# rm -rf ~/.ghmd

# #export SECRET_NETWORK_CHAIN_ID=ghmdev-1
# #export SECRET_NETWORK_KEYRING_BACKEND=test

# ghmd init banana --chain-id ghmdev-1
# perl -i -pe 's/"stake"/"uscrt"/g' ~/.ghmd/config/genesis.json
# echo "cost member exercise evoke isolate gift cattle move bundle assume spell face balance lesson resemble orange bench surge now unhappy potato dress number acid" |
#     ghmd keys add a --recover --keyring-backend test
# ghmd add-genesis-account "$(ghmd keys show -a --keyring-backend test a)" 1000000000000uscrt
# ghmd gentx a 1000000uscrt --chain-id ghmdev-1 --keyring-backend test
# ghmd collect-gentxs
# ghmd validate-genesis

# ghmd init-bootstrap node-master-cert.der io-master-cert.der
# ghmd validate-genesis

# RUST_BACKTRACE=1 ghmd start --bootstrap &


# export ghmd_PID=$(echo $!)


# until (ghmd status 2>&1 | jq -e '(.SyncInfo.latest_block_height | tonumber) > 0' &>/dev/null); do
#     echo "Waiting for chain to start..."
#     sleep 1
# done

# # ghmd rest-server --laddr tcp://0.0.0.0:1337 &
# export LCD_PID=$(echo $!)
# function cleanup() {
#     kill -KILL "$ghmd_PID" "$LCD_PID"
# }
# trap cleanup EXIT ERR

# store wasm code on-chain so we could later instansiate it
export STORE_TX_HASH=$(
    ghmd tx compute store erc20.wasm --from a --gas 10000000 --gas-prices 0.25uscrt --output json -y |
        jq -r .txhash
)

wait_for_tx "$STORE_TX_HASH" "Waiting for store to finish on-chain..."

# test storing of wasm code (this doesn't touch sgx yet)
    ghmd q tx "$STORE_TX_HASH" --output json |
        jq -e '.logs[].events[].attributes[] | select(.key == "code_id" and .value == "1")'

# init the contract (ocall_init + write_db + canonicalize_address)
# a is a tendermint address (will be used in transfer: https://github.com/CosmWasm/cosmwasm-examples/blob/f5ea00a85247abae8f8cbcba301f94ef21c66087/erc20/src/contract.rs#L110)
# secret1f395p0gg67mmfd5zcqvpnp9cxnu0hg6rjep44t is just a random address
# balances are set to 108 & 53 at init
export INIT_TX_HASH=$(
    ghmd tx compute instantiate 1 "{\"decimals\":10,\"initial_balances\":[{\"address\":\"$(ghmd keys show a -a)\",\"amount\":\"108\"},{\"address\":\"secret1f395p0gg67mmfd5zcqvpnp9cxnu0hg6rjep44t\",\"amount\":\"53\"}],\"name\":\"ReuvenPersonalRustCoin\",\"symbol\":\"RPRC\"}" --label RPRCCoin --from a --output json -y --gas-prices 0.25uscrt |
        jq -r .txhash
)

wait_for_tx "$INIT_TX_HASH" "Waiting for instantiate to finish on-chain..."

ghmd q compute tx "$INIT_TX_HASH" --output json

export CONTRACT_ADDRESS=$(
    ghmd q tx "$INIT_TX_HASH" --output json |
        jq -er '.logs[].events[].attributes[] | select(.key == "contract_address") | .value' |
        head -1
)

# test balances after init (ocall_query + read_db + canonicalize_address)
ghmd q compute query "$CONTRACT_ADDRESS" "{\"balance\":{\"address\":\"$(ghmd keys show a -a)\"}}" |
    jq -e '.balance == "108"'
ghmd q compute query "$CONTRACT_ADDRESS" "{\"balance\":{\"address\":\"secret1f395p0gg67mmfd5zcqvpnp9cxnu0hg6rjep44t\"}}" |
    jq -e '.balance == "53"'

# transfer 10 balance (ocall_handle + read_db + write_db + humanize_address + canonicalize_address)
ghmd tx compute execute "$CONTRACT_ADDRESS" '{"transfer":{"amount":"10","recipient":"secret1f395p0gg67mmfd5zcqvpnp9cxnu0hg6rjep44t"}}' --gas-prices 0.25uscrt --from a -b block -y --output json |
    jq -r .txhash |
    xargs ghmd q compute tx

# test balances after transfer (ocall_query + read_db)
ghmd q compute query "$CONTRACT_ADDRESS" "{\"balance\":{\"address\":\"$(ghmd keys show a -a)\"}}" |
    jq -e '.balance == "98"'
ghmd q compute query "$CONTRACT_ADDRESS" "{\"balance\":{\"address\":\"secret1f395p0gg67mmfd5zcqvpnp9cxnu0hg6rjep44t\"}}" |
    jq -e '.balance == "63"'

(ghmd q compute query "$CONTRACT_ADDRESS" "{\"balance\":{\"address\":\"secret1zzzzzzzzzzzzzzzzzz\"}}" || true) 2>&1 | grep -c 'canonicalize_address errored: invalid checksum'

# sleep infinity

(
    cd ./cosmwasm-js
    yarn
    cd ./packages/sdk
    yarn build
)

node ./cosmwasm/testing/cosmwasm-js-test.js

echo "All is done. Yay!"
