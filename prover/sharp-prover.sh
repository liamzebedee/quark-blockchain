
# Submit the proving job to SHARP.
SHARP_JOB_SUBMISSION=$(cairo-sharp submit --cairo_pie $TEMPDIR/pie.bin)
SHARP_JOB_ID=$(echo $SHARP_JOB_SUBMISSION | grep "^Job key" | cut -d' ' -f3)

# Await the proof to be generated, and then mined, on Eth Goerli.
cairo-sharp status $SHARP_JOB_ID

# Verify the fact.
SHARP_VERIFIER_CONTRACT=0xf457e4311f8229ab7b08191a6658112a29a962a9f2fe95d7a3d4f1200eef0195
cairo-sharp is_verified $SHARP_VERIFIER_CONTRACT --node_url=$ETH_RPC_URL