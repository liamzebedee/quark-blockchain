proof of concept
================

## Overview.

This PoC demoes the decoupled architecture + the stark proofs.

 * Sequencer - Tendermint blockchain built with [Lotion](https://lotionjs.com/).
 * Executor - 
   * Built atop Starkware's [Cairo](https://www.cairo-lang.org/).
   * Simple PoC of transactional memory. We run a program which accepts storage leaf inputs, performs some computation, and outputs the storage leaves written.
   * Generates proofs (using an open-source prover, [Giza](https://github.com/maxgillett/giza)) and sends them to the storage layer. 
 * Storage - 
   * Accepts execution receipts from executor, verifies the proofs, flushes the state.
   * Stores data in SQLite.

To-do:

 - [x] Implement sequencer
 - [x] Implement executer proof-of-concept
 - [x] Implement storage backend
 - [x] Setup simple e2e communications between all three
 - [ ] Functional Cairo prover
   - [x] [CLI to generate proofs](https://github.com/maxgillett/giza/pull/1)
   - [x] Reverse-engineer Cairo runner outputs
   - [x] implement cairo prime field
   - [ ] Parse cairo-runner output into winterfell structs
 - [ ] generate proofs
 - [ ] verify proofs on the storage node
 - [ ] test networking speed
 - [ ] simple web UI for realtime storage updates
 - [ ] deploy an EVM protocol (e.g. Lens) to this network

## Setup.

This will:

 * setup a Python virtual environment (for installing packages).
 * install my forked cairo-lang toolchain.

```sh
# Setup Python virtual env.
python3.7 -m venv ~/cairo_venv
source ~/cairo_venv/bin/activate

# Install this forked version of the cairo toolchain
# https://github.com/liamzebedee/cairo-lang
curl https://github.com/liamzebedee/cairo-lang/releases/download/runner-write-output/cairo-lang-0.8.2.1.zip cairo-lang-0.8.2.1.zip
pip3 install ./cairo-lang-0.8.2.1.zip

# Now setup deps for all packages.
cd execution/
npm i
# Build the Cairo executer program.
./scripts/build-run.sh

cd ../sequencer/
npm i 

cd ../storage
npm i
```

## Usage

Open 3 terminals and run each block below:

```sh
# Run the sequencer chain.
cd sequencer/
npm i 
npm run start

# This should output:
# (Use `node --trace-warnings ...` to show where the warning was created)
# Started sequencer chain
# Home: /Users/liamz/Documents/Projects/shard/cairo/sequencer/networks/example-chain
# GCI: 1daf0905e7d4f1231e72b364ca691af295dd8af84490d68d47b4961b455ffb62
```

```sh
# Run the storage network.
# This is stubbed out as a 1-node network right now for the PoC.
cd storage/

# Copy the GCI from the last step.
GCI=1daf0905e7d4f1231e72b364ca691af295dd8af84490d68d47b4961b455ffb62 npm run start
```

```sh
# Run an end-to-end test.
# 1. Create a tx.
# 2. Submit it to the sequencer
# 3. (Manually) submit it to the execution layer.
# 4. Generate a STARK proof.
# 5. Flush the writes to the storage layer.
./scripts/e2e.sh ./execution/input.json 97235716c360cf03425d36f3cfc09b9d99b7dd37f930b1391472db562a52cb5a https://goerli.infura.io/v3/fab0acebc2c44109b2e486353c230998
```