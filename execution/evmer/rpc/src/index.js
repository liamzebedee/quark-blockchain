const { execSync } = require('child_process')
const { resolve, join } = require('path')
const { readFileSync, existsSync } = require('fs');
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
const util = require('util')
const getTmpFilePath = () => {
    const tempDir = os.tmpdir();
    return join(tempDir, '/', randomUUID())
}
const jsonInTechnicolor = obj => util.inspect(obj, { compact: true, colors: true })


// 
// Blockchain parameters.
// 
const config = {
    goliathTestnet: {
        chainId: 0x420bae00,
        accounts: [
            // private key: 0xdd11a7ef293ec6bfb52b6cb2744b48106590ad3cb205c4333f954537bd50ed57
            '0x3756EfE4FF0FFB17Abd2Ea41d75F5711a702503F'
        ]
    }
}
const goliathChainConfig = Common.custom({ chainId: config.goliathTestnet.chainId })


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
    
    // TODO: HACK HACK HACK HACK HACK
    let outputBuf = '0x'
    if(existsSync(tempOutputFile)) {
        outputBuf = readFileSync(tempOutputFile, { encoding: 'hex' })
    }
    
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

const debugMiddleware = async (next, req, serverParams) => {
    console.log('> ' + jsonInTechnicolor(req))
    return next(req, serverParams).then((res) => {
        console.log(`${jsonInTechnicolor(res)}`);
        return res;
    });
}

// Add middleware for logging unknown methods.
server.applyMiddleware(debugMiddleware);


const unimplemented = params => { throw new Error("unimplemented") }
const unsupported = params => { throw new Error("unsupported RPC method") }
[
    'eth_coinbase',
    'eth_getTransactionByBlockHashAndIndex',
    'eth_getTransactionByBlockNumberAndIndex',
    'eth_getUncleByBlockHashAndIndex',
    'eth_getUncleByBlockNumberAndIndex',
    'eth_getUncleCountByBlockHash',
    'eth_getUncleCountByBlockNumber'
].map(method => server.addMethod(method, unsupported));

// 
// Transactions.
// 

const toRawTx = (tx) => {
    const txRaw = {
        data: bufferToHex(tx.data),
        from: bufferToHex(tx.getSenderAddress().buf),
        to: bufferToHex(tx.to),
        gas: bufferToHex(tx.gasLimit),
        gasPrice: bufferToHex(tx.gasPrice),
        value: bufferToHex(tx.value),
    }
    return txRaw
}

server.addMethod('eth_estimateGas', params => {
    return '0x5208'
})

let __temp__txs = {}

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

server.addMethod('eth_sendTransaction', unimplemented)
// server.addMethod("eth_sendTransaction", (params) => {
//     const [txData, block] = params

//     let tx
//     try {
//         tx = TransactionFactory.fromTxData(txData, { common: goliathChainConfig })
//     } catch (e) {
//         throw e
//         throw {
//             // code: PARSE_ERROR,
//             message: `serialized tx data could not be parsed (${e.message})`,
//         }
//     }

//     console.log(tx)
//     console.log(toRawTx(tx))

//     // return executeVM({ tx, write: true })
// });

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
    let txHash = '0xe3c6fd52bce67fc915be905a22956b6f7df60dc4e7da796e6fe8b2c25eb4f504'
    return txHash
});

server.addMethod('eth_getTransactionReceipt', (params) => {
    // TODO: stubbed.
    return {
        transactionHash: '0xe3c6fd52bce67fc915be905a22956b6f7df60dc4e7da796e6fe8b2c25eb4f504',
        transactionIndex: '0x1',
        blockNumber: 0x420,
        blockHash: '0xe3c6fd52bce67fc915be905a22956b6f7df60dc4e7da796e6fe8b2c25eb4f504',
        cumulativeGasUsed: '0x33bc',
        gasUsed: '0x4dc',
        // or null, if none was created
        // TODO: handle if contract was created.
        contractAddress: '0x' + '1'.repeat(40),
        logs: [],
        logsBloom: "0xe3c6fd52bce67fc915be905a22956b6f7df60dc4e7da796e6fe8b2c25eb4f504", // 256 byte bloom filter
        // TODO: return appropriate status.
        status: '0x1'
    }
})

server.addMethod('eth_getTransactionByHash', params => {
    const [txHash] = params
    return {
        "hash": txHash,
        "blockHash": "0x1d59ff54b1eb26b013ce3cb5fc9dab3705b415a67127a003c3e61eb445bb8df2",
        "blockNumber": "0x5daf3b",
        "from": "0xa7d9ddbe1f17865597fbd27ec712455208b6b76d",
        "gas": "0xc350",
        "gasPrice": "0x4a817c800",
        "input": "0x68656c6c6f21",
        "nonce": "0x15",
        "r": "0x1b5e176d927f8e9ab405058b2d2457392da3e20f328b16ddabcebc33eaac5fea",
        "s": "0x4ba69724e8f69de52f0125ad8b3c5c2cef33019bac3249e2c0a2192766d1721c",
        "to": "0xf02c1c8e6114b1dbe8937a39260b5b0a374432bb",
        "transactionIndex": "0x41",
        "v": "0x25",
        "value": "0xf3dbb76162000"
    }
})

// 
// Filters.
// 

server.addMethod('eth_newFilter', unimplemented)

server.addMethod('eth_newBlockFilter', unsupported)
server.addMethod('eth_newPendingTransactionFilter', unsupported)

server.addMethod('eth_uninstallFilter', unimplemented)
server.addMethod('eth_getFilterChanges', unimplemented)
server.addMethod('eth_getFilterLogs', unimplemented)
server.addMethod('eth_getLogs', unimplemented)

// 
// World state.
// 

// Accounts.

server.addMethod('eth_getTransactionCount', (params) => {
    return '0x1'
})

server.addMethod('eth_getBalance', (params) => {
    return '0x' + 'f'.repeat(40)
})

server.addMethod('eth_accounts', params => {
    return config.goliathTestnet.accounts
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

;[
    'eth_getBlockByHash',
    'eth_getBlockByNumber',
    'eth_getBlockTransactionCountByHash',
    'eth_getBlockTransactionCountByNumber'
].map((method) => server.addMethod(method, (params) => '0x1'))

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
// Blockchain & Network.
// 

server.addMethod('eth_chainId', (params) => {
    return intToHex(config.goliathTestnet.chainId)
})

server.addMethod('net_version', params => {
    throw new Error("Unimplemented")
})

// 
// Software.
// 

server.addMethod('web3_clientVersion', params => {
    return "Goliath-Eth-RPC/v0.1.0"
})





// 
// HTTP app.
//


const app = express();
app.use(bodyParser.json());

app.post("/", (req, res) => {
    const jsonRPCRequest = req.body;
    
    console.debug(req.body)
    
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