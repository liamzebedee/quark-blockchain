prover
======

A prover converts a Cairo execution trace into a STARK proof. The execution trace is currently formatted as a Position Independent Execution (PIE) file, which contains a list of the memory segments used by the Cairo program (execution memory, output memory, etc) which can be relocated.

Starkware's prover is modeled after a fact registry. The program is executed with inputs, outputting an execution trace, which is reduced to a STARK proof. The Cairo STARK proof verifies that running a program with those inputs will generate this output - this is the fact we are submitting to the fact registry. The fact registry is a [smart contract on Ethereum Goerli](https://twitter.com/liamzebedee/status/1524987018110849025), which verifies STARK proofs and stores facts that are of the form `keccak(program_hash, output_hash)`, where `program_hash` is the Pedersen hash of the compiled program, and `output_hash` is the keccak hash of the output field elements (which we can get from `--program_output` after running cairo-runner). 

Starkware have not open-sourced their prover yet, and we can only rely on their [SHARP prover service](https://www.cairo-lang.org/docs/sharp.html). **The problem** is that this service submits proofs to the Ethereum Goerli testnet, on a schedule which is **wayy too slow** for this PoC. 

One alternative is integrating open-source Cairo provers, such as [giza](https://github.com/maxgillett/giza). Giza is not yet ready, though we're in contact and awaiting their completion.

In the meantime, this implements a **mock prover** - which aims to simulate the same aspects of proof generation (proving time, proof size, etc).

## Install.

```sh
# Clone the subrepos/
git submodule sync
git submodule update

# Copy the execution resources to a directory the prover can access
cp -R execution/out prover/giza/prover/resources

# Run the prover.
docker run --mount type=bind,src=$(pwd)/giza,dst=/app/giza --mount type=bind,src=$(pwd)/winterfell,dst=/app/winterfell -it a82bf5cf28b6287f043734c6df44ef9e0d77b68a9220226baf2859e998569972 bash
# Inside the container.
cd /app/giza
# Generate a proof for a cairo-runner output.
cargo run --bin giza prove --trace prover/resources/out/trace.bin --memory prover/resources/out/memory.bin --pie prover/resources/out/pie.zip --compiled prover/resources/out/executor_compiled.json --output ''
```

### Computing the fact.

```py
from web3 import Web3
program_hash = 0x4cbc2dafc7f58fc1f8235d3edfb8eaa730a25562b475c849701dbf61949ff00
program_output = [1, 2, 3]
Web3.solidityKeccak([‘uint256‘, ‘bytes32‘], [
    program_hash,
    Web3.solidityKeccak([‘uint256[]‘], [program_output])
```

Source: https://www.cairo-lang.org/playground-sharp-alpha/

