#!/bin/env sh
set -ex

# Tendermint Global Chain Identifier (GCI).
export GCI=0x
export ETH_RPC_URL=""



# TODO: hash program_input.json
export TX_HASH=""


# 
# Sequence transaction.
# 

lotion send $GCI '{ "hash" : "$TX_HASH" }'

# Response:
# {
#   "check_tx": {},
#   "deliver_tx": {},
#   "hash": "B8E5342EF4367A0A23DF14662DB13F9B302676F65BBC9BF83533B0A2932AE8FE",
#   "height": "105"
# }




# 
# Executor.
# 


cairo-compile executor.cairo --output executor_compiled.json

echo "Executing transaction"
# cairo-run --program=executor_compiled.json --print_output --layout=small --program_input=input.json
TXID=$(cairo-sharp submit --source executor.cairo --program_input input.json)

echo "Verifying transaction"
cairo-sharp status $TXID
cairo-sharp is_verified 0xf457e4311f8229ab7b08191a6658112a29a962a9f2fe95d7a3d4f1200eef0195 --node_url=$ETH_RPC_URL


echo "Writing storage leaves"

# Extract the modified storage leaves from here,
# select the correct storage nodes to flush them to,
# And write to their API-
curl -X POST http://localhost:3000/write -H "Content-Type: application/json" -d '{"tx":1}'