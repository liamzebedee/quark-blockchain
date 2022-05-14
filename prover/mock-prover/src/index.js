const app = require('./api')

async function run() {
    console.log('Starting mock prover service')

    // Run a HTTP server.
    const port = 3001
    app.listen(port, () => {
        console.log(`API server listening on http://localhost:${port}`)
    });
}

run().catch(ex => { throw ex })