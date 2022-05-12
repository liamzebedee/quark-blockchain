let lotion = require('lotion')
const { join } = require('path')

const CHAIN_GCI = 'bb9d9d9618a925b1d34188cccbdea589'

const NETWORK_DIR = join(__dirname, '../networks/', CHAIN_GCI, '/')
let app = lotion({
    initialState: {
        clock: 0,
        txs: {}
    },
    keyPath: join(NETWORK_DIR, '/config/priv_validator_key.json'),
    genesisPath: join(NETWORK_DIR, '/config/genesis.json'),
})

function transactionHandler(state, transaction) {
    let time = state.clock
    state.txs[transaction.hash] = time
    state.clock += 1
}

app.use(transactionHandler)

app.start().then(appInfo => {
    console.log(`Started sequencer chain`)
    console.log(`Home: ${appInfo.home}`)
    console.log(`GCI: ${appInfo.GCI}`)
})
