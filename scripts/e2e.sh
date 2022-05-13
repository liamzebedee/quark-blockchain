#!/usr/bin/env bash
# 
# Performs an end-to-end test of the quark blockchain.
# 
# Usage: e2e.sh <tx_input> <gci> <eth_rpc_url>
# Arguments:
#   tx_input - path to the transaction's input.json.
#   gci - the global chain identifier.
#   eth_rpc_url - the ethereum node rpc url.
# 
set -ex

# Globals.
TEMPDIR=$(mktemp -d)

# Argument parsing.
# 
export TX_INPUT=$1
# Tendermint Global Chain Identifier (GCI).
export GCI=$2
export ETH_RPC_URL=$3


# 
# Sequence transaction.
# 

echo Transaction: $TX_INPUT

export TX_HASH=$(cat $TX_INPUT | sha256sum | awk '{print $1}')
echo Transaction hash: $TX_HASH

export SEQUENCER_BODY=$(jq --null-input \
    --arg TX_HASH "$TX_HASH" \
    '{ "hash": $TX_HASH }')

lotion send $GCI "${SEQUENCER_BODY}"
read

# Response:
# {
#   "check_tx": {},
#   "deliver_tx": {},
#   "hash": "B8E5342EF4367A0A23DF14662DB13F9B302676F65BBC9BF83533B0A2932AE8FE",
#   "height": "105"
# }


# 
# Execute transaction.
# 

echo "Executing transaction"
cairo-run --program=execution/out/executor_compiled.json --layout=small --program_input=$TX_INPUT --program_output_file $TEMPDIR/output.json --cairo_pie_output $TEMPDIR/pie.bin

echo "Generating STARK proof"


echo "Verifying transaction"


echo "Writing storage leaves"

# Extract the modified storage leaves from here,
# select the correct storage nodes to flush them to,
# And write to their API-
curl -X POST http://localhost:3000/write -H "Content-Type: application/json" -d '{"tx":1}'