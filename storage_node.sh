#!/bin/env sh
set -ex

export ETH_RPC_URL=""

cairo-compile example.cairo --output example_compiled.json

echo "Executing transaction"
TXID=$(cairo-sharp submit --source example.cairo --program_input input.json)

echo "Verifying transaction"
cairo-sharp status $TXID
cairo-sharp is_verified 0xf457e4311f8229ab7b08191a6658112a29a962a9f2fe95d7a3d4f1200eef0195 --node_url=$ETH_RPC_URL

echo "Writing storage leaves"
cairo-run --program=example_compiled.json --print_output --layout=small --program_input=input.json
# Extract the modified storage leaves from here, and flush them to the db.