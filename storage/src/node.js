const { performance } = require('node:perf_hooks');
const { join, resolve } = require('path')
const Level = require('level')
let { connect } = require('lotion')

// high-accuracy timer for measuring performance
function perftimer() {
    const start = performance.now()
    const end = () => performance.now() - start
    return {
        end
    }
}

// Config.
// 

// Global Chain Identifier for sequencer.
const GCI = process.env.GCI

class Node {
    constructor() {
    }

    static async create({ dataDir }) {
        let self = new Node()

        // Setup LevelDB backend.
        self.db = new Level(join(dataDir, 'db'), { valueEncoding: 'json' })

        // Connect to sequencer via the Lotion light client.
        console.log(`Connecting to sequencer GCI=${GCI}`)
        let { state } = await connect(GCI)
        // Note: the light client uses a Proxmise-based API,
        // which basically means accessing a property is proxied into an async request
        // to the sequencer. It's quite ergonomic for this PoC.
        self.sequencerState = state

        const sequencerClock = await self.sequencerState.clock
        console.log(`Connected to sequencer`)
        console.log(`clock=${sequencerClock}`)

        return self
    }

    async write({
        proof,
        txHash,
        txOutput
    }) {
        // (1) Verify transaction has been sequenced.
        // 
        console.debug(`Verifying sequence txHash=${txHash}`)
        const sequence = await this.sequencerState.txs[txHash]
        console.debug(`txHash=${txHash} sequence=${sequence}`)

        // (2) Verify proof asserts the fact:
        // keccak(program_hash, output_hash)
        // This validates txOutput.
        // 
        // 
        // TODO: !!!!! verify txHash
        const QUARK_BOOTLOADER_HASH = '0x'
        const programHash = QUARK_BOOTLOADER_HASH
        const outputHash = pedersenHash(txOutput)
        const factHash = pedersenHash(programHash, outputHash)
        console.debug(`Verifying proof txHash=${txHash}`)
        const proof_timer = perftimer()
        verifyProof(proof, factHash)
        console.debug(`Proof verified in ${proof_timer.end()} ms`)

        // (3) Commit the storage writes.
        // 
        const leaves = parseExecutionOutput(txOutput)
        
        // Verify leaves are hosted by this storage node.
        // for (let leaf of leaves) {
        //     if (leaf.key) continue
        // }
        
        console.debug(`Writing leaves to storage txHash=${txHash} leaves=[${leaves.map(l => l.key)}]`)
        const writes = leaves.map(leaf => {
            return {
                type: 'put',
                key: leafKey(sequence, leaf.key),
                value: leaf.val,
                hash: leaf.hash
            }
        })
        await this.db.batch(writes)
        console.debug(`Write complete txHash=${txHash}`)
    }
}

function pedersenHash() { /* TODO */ return '' }

function verifyProof(proof, expectedHash) {
    const hash = ''
    return hash
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

const leafKey = (sequence, slotKey) => `${slotKey}_${sequence}`

module.exports = {
    Node
}