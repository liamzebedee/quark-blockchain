const { Node } = require('./node')
const { APIServer } = require('./api-server')
const { join } = require('path')

async function run() {
    console.log('Starting storage node')
    const node = await Node.create({
        dataDir: join(__dirname, '../node_data')
    })

    const apiServer = await APIServer.create(node)
    
    // Run a HTTP server.
    const port = 3001
    apiServer.listen(port, () => {
        console.log(`API server listening on http://localhost:${port}`)
    });
}

run().catch(ex => { throw ex })