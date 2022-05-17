#!/usr/bin/env bash
# 
# Performs an end-to-end test of the quark blockchain.
# 
# Usage: e2e.sh <TX_INPUT_PATH> <gci> <eth_rpc_url>
# Arguments:
#   TX_INPUT_PATH - path to the transaction's input.json.
#   gci - the global chain identifier.
#   eth_rpc_url - the ethereum node rpc url.
# 
set -ex

# Globals.
TEMPDIR=$(mktemp -d)

# Argument parsing.
# 
export TX_INPUT_PATH=$1
# Tendermint Global Chain Identifier (GCI).
export GCI=$2
export ETH_RPC_URL=$3


# 
# Sequence transaction.
# 

echo Transaction: $TX_INPUT_PATH
cp $TX_INPUT_PATH $TEMPDIR/tx-input.json

export TX_HASH=$(cat $TX_INPUT_PATH | sha256sum | awk '{print $1}')
echo Transaction hash: $TX_HASH

export SEQUENCER_BODY=$(jq --null-input \
    --arg TX_HASH "$TX_HASH" \
    '{ "hash": $TX_HASH }')

lotion send $GCI "${SEQUENCER_BODY}"

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

# Simple interrupt-based interpreter
# when it reads a storage_read or storage_write call, it intercepts it and performs a call to the storage node.
echo "Executing transaction"
cairo-run --program=execution/out/executor_compiled.json --layout=small --program_input=$TX_INPUT_PATH --program_output_file $TEMPDIR/output.json --cairo_pie_output $TEMPDIR/pie.bin

echo "Generating STARK proof"
echo "{}" > $TEMPDIR/proof.json

echo "Flushing writes to storage"
node ./execution/src/flush-writes.js --proof $TEMPDIR/proof.json --tx-input $TEMPDIR/tx-input.json --tx-hash $TX_HASH --tx-output $TEMPDIR/output.json
