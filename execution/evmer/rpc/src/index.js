const { execSync } = require('child_process')
const { resolve, join } = require('path')
const { readFileSync } = require('fs');
const express = require("express");
const bodyParser = require("body-parser");
const { JSONRPCServer } = require("json-rpc-2.0");

const {
    TransactionFactory,
} = require('@ethereumjs/tx')
const {
    Account,
    Address,
    BN,
    bufferToHex,
    bnToHex,
    intToHex,
    rlp,
    toBuffer,
} = require('ethereumjs-util')

// TODO: the default stuff is ugly.
const Common = require('@ethereumjs/common').default

// Helpers.
const { randomUUID } = require('crypto');
const os = require("os");
const getTmpFilePath = () => {
    const tempDir = os.tmpdir();
    return join(tempDir, '/', randomUUID())
}


// 
// Blockchain parameters.
// 
const config = {
    goliath: {
        chainId: 0x420bae00
    }
}
const goliathChainConfig = Common.custom({ chainId: config.goliath.chainId })


// Sputnik VM interop.
// 

const binary = process.env.DEV === '1' ? 'RUST_BACKTRACE=1 cargo run --' : './target/release/quarkevm'
const SPUTNIK_EXECUTOR_PATH = resolve(process.env.SPUTNIK_EXECUTOR_PATH)

/**
 * Executes the transcation inside the Sputnik VM, returning the output as hex data.
 */
function executeVM(opts) {
    const write = opts.write || false
    const tx = opts.tx

    // Execute the VM, passing the transaction as a CLI input.
    // The output is written to a file.
    const tempOutputFile = getTmpFilePath();
    const sanitizedInput = `'${JSON.stringify(tx)}'`
    
    // Construct command and arguments.
    let cmd = `${binary}`
    let args = []
    args.push(`--db-path ./chain.sqlite`)
    args.push(`--data ${sanitizedInput}`)
    args.push(`--output-file ${tempOutputFile}`)
    if(write) args.push('--write')

    cmd += ' ' + args.join(' ')
    console.log(cmd)
    execSync(cmd, { cwd: resolve(SPUTNIK_EXECUTOR_PATH) })

    let outputBuf = readFileSync(tempOutputFile, { encoding: 'hex' })
    return '0x' + outputBuf
}





// 
// ============
// RPC methods.
// ============
// 

/**
 * NOTES:
 * 
 * The following methods have an extra default block parameter:

    eth_getBalance
    eth_getCode
    eth_getTransactionCount
    eth_getStorageAt
    eth_call
 */

const server = new JSONRPCServer();

// 
// Transactions.
// 

server.addMethod('eth_estimateGas', params => {
    return '0x1'
})

server.addMethod("eth_call", (params) => {
    let tx = {}
    if(params.length) {
        // Handle block parameter.
        // [tx, blockNumber]
        tx = params[0]
    } else {
        tx = params
    }

    // We don't support different transaction types,
    // access list will come later.
    delete tx.accessList
    delete tx.type

    return executeVM({ tx, write: false })
});

server.addMethod("eth_sendTransaction", (params) => {
    const sanitizedInput = `'${JSON.stringify(params)}'`

    return executeVM({ tx, write: true })
});

server.addMethod("eth_sendRawTransaction", (params) => {
    const [serializedTx] = params

    let tx
    try {
        tx = TransactionFactory.fromSerializedData(toBuffer(serializedTx), { common: goliathChainConfig })
    } catch (e) {
        throw e
        throw {
            // code: PARSE_ERROR,
            message: `serialized tx data could not be parsed (${e.message})`,
        }
    }

    if (!tx.isSigned()) {
        throw {
            // code: INVALID_PARAMS,
            message: `tx needs to be signed`,
        }
    }

    // Now we reconstruct a raw JSON form.
    const from = bufferToHex(tx.getSenderAddress().buf)
    console.log(`signed tx from ${from}`)

    const txRaw = {
        data: bufferToHex(tx.data),
        from: bufferToHex(tx.getSenderAddress().buf),
        to: bufferToHex(tx.to),
        gas: bufferToHex(tx.gasLimit),
        gasPrice: bufferToHex(tx.gasPrice),
        value: bufferToHex(tx.value),
    }

    executeVM({ tx: txRaw, write: true })

    // TODO: tx hash, is that of the literal hash in the mempool?
    let txHash = '0xBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeBe'
    return txHash
});

server.addMethod('eth_getTransactionReceipt', (params) => {
    // TODO: stubbed.
    return {
        transactionHash: '0xBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeBe',
        transactionIndex: '0x1',
        blockNumber: 0x420,
        blockHash: '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        cumulativeGasUsed: '0x33bc',
        gasUsed: '0x4dc',
        // or null, if none was created
        // TODO: handle if contract was created.
        contractAddress: '0x',
        logs: [{
            // logs as returned by getFilterLogs, etc.
        },],
        logsBloom: "0x00000000000000000000000000000000", // 256 byte bloom filter
        // TODO: return appropriate status.
        status: '0x1'
    }
})

// 
// Filters.
// 

server.addMethod('eth_newFilter', params => {

})

server.addMethod('eth_newBlockFilter', params => {
    throw new Error("Unsupported RPC method.")
})

server.addMethod('eth_newPendingTransactionFilter', params => {
    throw new Error("Unsupported RPC method.")
})

server.addMethod('eth_uninstallFilter', params => {

})

server.addMethod('eth_getFilterChanges', params => {})
server.addMethod('eth_getFilterLogs', params => {})
server.addMethod('eth_getLogs', params => {})

// 
// World state.
// 

// Accounts.

server.addMethod('eth_getTransactionCount', (params) => {
    return '0x1'
})

server.addMethod('eth_getBalance', (params) => {
    return '0x1'
})

// Code + storage.

server.addMethod('eth_getCode', (params) => {
    return '0x1A40' // 4200
})

server.addMethod('eth_getStorageAt', (params) => {
    return '0x1A40' // 4200
})

// 
// Blocks.
// 

server.addMethod('eth_chainId', (params) => {
    return config.goliath.chainId
})

server.addMethod('eth_blockNumber', (params) => {
    return '0x1'
})

// 
// Gas market.
// 

server.addMethod('eth_gasPrice', (params) => {
    return '0x1'
})








// 
// HTTP app.
//

const app = express();
app.use(bodyParser.json());

app.post("/", (req, res) => {
    const jsonRPCRequest = req.body;

    server.receive(jsonRPCRequest).then((jsonRPCResponse) => {
        if (jsonRPCResponse) {
            res.json(jsonRPCResponse);
        } else {
            // If response is absent, it was a JSON-RPC notification method.
            // Respond with no content status (204).
            res.sendStatus(204);
        }
    });
});

const PORT = process.env.PORT || 8545

console.log(`Listening on http://localhost:${PORT}`)
console.log(`SPUTNIK_EXECUTOR_PATH = ${SPUTNIK_EXECUTOR_PATH}`)
app.listen(PORT);