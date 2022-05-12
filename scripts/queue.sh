set -ex

# Tendermint Global Chain Identifier (GCI).
export GCI=0x

lotion send $GCI '{ "hash" : "123" }'

# Response:
# {
#   "check_tx": {},
#   "deliver_tx": {},
#   "hash": "B8E5342EF4367A0A23DF14662DB13F9B302676F65BBC9BF83533B0A2932AE8FE",
#   "height": "105"
# }