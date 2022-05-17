// Library which supports parsing BigInt's in JSON representations.
const JSONbig = require('json-bigint');
const { readFileSync } = require('fs')
const { Command } = require('commander');
const fetch = require('node-fetch')

// Helpers.
function readJsonWithBigInts(path) {
    const content = readFileSync(path, 'utf-8')
    return JSONbig.parse(content)
}


// CLI.
const program = new Command();
program
    .description('Flush writes to storage')
    .requiredOption('--proof <path>', 'path to generated STARK proof')
    .requiredOption('--tx-input <path>', 'path to the transaction input')
    .requiredOption('--tx-hash <hash>', 'transaction hash')
    .requiredOption('--tx-output <path>', 'path to the transaction output memory')

async function run() {
    program.parse();
    
    const {
        proof,
        txInput,
        txHash,
        txOutput
    } = program.opts();

    return flushLeaves({
        proof:    require(proof),
        txInput:  txInput,
        txHash:   txHash,
        txOutput: readJsonWithBigInts(require.resolve(txOutput))
    })
}


// Logic.
const STORAGE_NODE_RPC_URL = 'http://localhost:3001'

async function flushLeaves({ proof, txInput, txHash, txOutput }) {
    // Extract leaves to write to.
    const leaves = parseExecutionOutput(txOutput)
    console.log(leaves)

    // Format a proof.
    // Send to the storage node.
    const writeArgs = {
        proof,
        txHash,
        txOutput,
    }

    console.log('Writing to storage node')
    console.log(writeArgs)
    const writeRes = await fetch(`${STORAGE_NODE_RPC_URL}/write`, {
        method: 'post',
        body: JSON.stringify(writeArgs),
        headers: { 'Content-Type': 'application/json' }
    });
    const data = await writeRes.json();
    console.log(data)
}

function parseExecutionOutput(txOutput) {
    let leaves = []
    if (txOutput.output_memory.length % 3 != 0) {
        throw new Error('output memory should be a multiple of 3, ie. a set of triples (key, val, hash)')
    }
    for (let i = 0; i < txOutput.output_memory.length; i += 3) {
        const key = txOutput.output_memory[i]
        const val = txOutput.output_memory[i + 1]
        const hash = txOutput.output_memory[i + 2]
        leaves.push({ key, val, hash })
    }
    
    return leaves
}

run().catch(ex => { throw ex; })